module ::ObjectFieldable

  def self.included(base)
    base.class_eval do
      has_many :object_field_instances, as: :object_table, after_add: :try_touch, after_remove: :try_touch
      has_many :object_fields, :through => :object_field_instances

      validate :object_field_instance_validator, :on => :create
      accepts_nested_attributes_for :object_field_instances, :allow_destroy => true

      def self.spawned_from_class
        if self.class_variable_defined? :@@spawned_from
          return self.class_variable_get :@@spawned_from
        end
        return nil
      end

      def self.spawned_from(klass)
        self.class_variable_set(:@@spawned_from,klass)
      end

      def self.with_object_fields(*object_field_ids)
        self.includes(:object_field_instances).where(:object_field_instances => {:object_field_id => object_field_ids})
      end

      def self.with_object_field_instance_values(hash)
        object_field_ids = hash.keys
        c = self.where(:object_field_instances => {:object_field_id => object_field_ids})

        wheres = []
        wheres_placeholders = []
        hash.each_pair do |object_field_id, values|
          values = [ values ] unless values.kind_of? Array
          sub_wheres = []
          sub_where = ""
          sub_where << "object_field_instances.object_table_type = '#{self.to_s}' AND "
          sub_where << "object_field_instances.object_table_id = #{self.table_name}.id AND "
          sub_where << "object_field_instances.object_field_id = ?"
          wheres_placeholders << object_field_id
          values.each do |value|
            if %w(1 true).include?(value.to_s.downcase)
              sub_wheres << "object_field_instances.value ILIKE '%true%' OR object_field_instances.value ILIKE '%1%'"
            elsif %w(0 false).include?(value.to_s.downcase)
              sub_wheres << "object_field_instances.value ILIKE '%false%' OR object_field_instances.value ILIKE '%0%'"
            else
              sub_wheres << "object_field_instances.value ILIKE ?"
              wheres_placeholders << "%#{value}%"
            end

          end
          wheres << "EXISTS(SELECT 1 FROM object_field_instances WHERE #{sub_where} AND (#{sub_wheres.join(" OR ")}))"
        end
        c.joins(:object_field_instances).where(wheres.join(" AND "), *wheres_placeholders)
        .references(:object_field_instances).group("#{self.table_name}.id")
      end
    end
  end

  def has_object_field_instance object_field_id, *values
    return self.object_field_instances.where(:object_field_id => object_field_id).where(:value => values).count > 0
  end

  def object_field_instance_validator
    # Ensure spawned_from_class object exists
    if(self.send("#{self.class.spawned_from_class}").nil?)
      errors.add(:template, "is missing")
      return
    end

    # Ensure all required fields are present
    required_fields = self.send("#{self.class.spawned_from_class}").object_fields.required.pluck(:id)
    submitted_fields = self.object_field_instances.map(&:object_field_id)
    ObjectField.where(:id => (required_fields - submitted_fields)).each do |missing_field|
      errors.add(:object_field_instances, "#{missing_field.name} is required")
    end
    # Check required object fields
    self.object_field_instances.each do |object_field_instance|
      if object_field_instance.object_field.nil?
        errors.add(:object_field_instances, "object_field_id can't be nil")
      elsif object_field_instance.object_field.is_allow_null == false
        show_error = false
        if object_field_instance.value.blank?
          show_error = true
        end
        if object_field_instance.object_field.data_type == ObjectField::DataType::TypeBoolean and !object_field_instance.value.to_bool
          show_error = true
        end
        if show_error
          message = "'#{object_field_instance.object_field.name}' is a required field"
          if errors.messages[:'object_field_instances.value'].present? && errors.messages[:'object_field_instances.value'][0].blank?
            errors.messages[:'object_field_instances.value'][0] = message
          else
            errors.add('object_field_instances.value', message)
          end
        end
      end
    end
  end

  def siren_attributes
    extras = {
        :object_field_instances => self.object_field_instances.map(&:siren_attributes),
        :object_fields => self.object_fields.map(&:siren_attributes)
    }
    super.merge extras
  end

  protected
  def try_touch object_field_instance
    self.touch if self.persisted?
  end
end
