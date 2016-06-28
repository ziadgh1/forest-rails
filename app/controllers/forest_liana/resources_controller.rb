module ForestLiana
  class ResourcesController < ForestLiana::ApplicationController
    begin
      prepend ResourcesExtensions
    rescue NameError
    end

    before_filter :find_resource

    def index
      getter = ResourcesGetter.new(@resource, params)
      getter.perform

      render serializer: nil, json: serialize_models(getter.records,
                                                     include: includes,
                                                     count: getter.count,
                                                     params: params)
    end

    def show
      getter = ResourceGetter.new(@resource, params)
      getter.perform

      render serializer: nil, json:
        serialize_model(getter.record, include: includes)
    end

    def create
      getter = ResourceCreator.new(@resource, params)
      getter.perform

      ActivityLogger.new.perform(current_user, 'created', params[:collection],
                                getter.record.id)

      render serializer: nil,
        json: serialize_model(getter.record, include: includes)
    end

    def update
      getter = ResourceUpdater.new(@resource, params)
      getter.perform

      ActivityLogger.new.perform(current_user, 'updated', params[:collection],
                                getter.record.id)

      render serializer: nil,
        json: serialize_model(getter.record, include: includes)
    end

    def destroy
      @resource.destroy_all(id: params[:id])
      ActivityLogger.new.perform(current_user, 'deleted', params[:collection],
                                params[:id])
      render nothing: true, status: 204
    end

    private

    def find_resource
      @resource = SchemaUtils.find_model_from_table_name(params[:collection])

      if @resource.nil? || !@resource.ancestors.include?(ActiveRecord::Base)
        render serializer: nil, json: {status: 404}, status: :not_found
      end
    end

    def resource_params
      ResourceDeserializer.new(@resource, params[:resource]).perform
    end

    def includes
      SchemaUtils.one_associations(@resource).map {|a| a.name.to_s}
    end

  end
end
