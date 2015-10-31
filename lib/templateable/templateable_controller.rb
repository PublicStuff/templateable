module TemplateableController

  def TemplateableController.swagger controller, action, api
    root = controller.resource_class.name.underscore
    case action
      when :index
        api.param :query, :with_object_field_names, :array_or_scalar, :optional, "Show only #{controller.resource_class.name} with specified object field names"
        api.param :query, :has_object_fields, :boolean, :optional, "Show only #{controller.resource_class.name} with object fields"
      when :create,:update
        root = controller.resource_class.name.underscore
        #TODO: Find better way to manage the Array of objects
        5.times do
          ObjectField.writable_columns.each do |c|
            api.param :form, "#{root}[object_fields_attributes][][#{c.name}]", "#{c.type}", :optional
            #TODO: Find better way to manage the Array of objects
            5.times do
              ObjectFieldOption.writable_columns.each do |c|
                api.param :form, "#{root}[object_fields_attributes][][object_field_options_attributes][][#{c.name}]", "#{c.type}", :optional
              end
            end
          end
        end
        #TODO: Find better way to manage the Array of objects
        5.times do
          api.param :form, "#{root}[object_field_ids][]", :integer, :optional, "Bind the set of object field ids to the object (Overrides existing values)"
        end
    end
  end


  def self.included(base)
    base.class_eval do
      before_filter :only => [:create,:update] do
        key = resource_class.to_s.underscore.to_sym
        params[key][:object_field_ids] ||= [] if params[key].has_key? :object_field_ids
      end

      before_action :index_order_index, :only => :index
      before_action :show_order_index, :only => :show
    end
  end

  def index
    object_field_names = params[:with_object_field_names]
    unless object_field_names.nil? or object_field_names.empty?
      set_collection_ivar collection.with_object_field_names object_field_names
    end

    has_object_fields = params[:has_object_fields]
    unless has_object_fields.nil?
      if has_object_fields === 'true'
        set_collection_ivar collection.has_object_fields
      else
        set_collection_ivar collection.has_object_fields false
      end
    end


    super
  end

  def index_order_index
    set_collection_ivar collection.includes(:object_field_associations)
    @order_indicies = {}
    collection.each do |item|
      next if item.object_field_associations.empty?
      @order_indicies[item.id] = {}.tap{ |h| item.object_field_associations.each{ |ofa| h[ofa.id] = ofa.order_index } }
    end
  end

  def show_order_index
    @order_indicies = {resource.id => {}.tap{ |h| resource.object_field_associations.each{ |ofa| h[ofa.id] = ofa.order_index }}}
  end
end

