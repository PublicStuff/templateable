
module ::Templatable

  def self.included(base)
    base.class_eval do
      has_many :object_field_associations, :as => :object_table, :dependent => :destroy, :counter_cache => true
      has_many :object_fields, :through => :object_field_associations

      accepts_nested_attributes_for :object_fields, allow_destroy: true

      def self.spawns_class
        if self.class_variable_defined? :@@spawns
          return self.class_variable_get :@@spawns
        end
        return nil
      end

      def self.spawns(klass)
        self.class_variable_set(:@@spawns,klass)
      end

      def self.with_object_fields(*object_field_ids)
        self.joins(:object_fields).where(:object_field_id => object_field_ids)
      end

      def self.has_object_fields(flag = true)
        if(flag)
          self.where("#{self.table_name}.object_fields_count > 0")
        else
          self.where("#{self.table_name}.object_fields_count = 0")
        end
      end

      def self.with_object_field_names(*names)
        self.joins(:object_fields).where(:object_fields => { :name => names })
      end
    end
  end

  def accessible_object_fields user = nil
    user ||= User.current_user
    user_id = user.try(:id)
    (@allowed_object_fields ||= {})[user_id] ||=
        begin
          keep = []
          self.object_fields.each do |of|
            user_group_ids = user.try(:cached_user_group_ids) || []
            of_group_ids = of.read_group_ids
            keep << of if(of_group_ids.empty? || !(of_group_ids & user_group_ids).empty?)
          end
          keep
        end
    @allowed_object_fields[user_id]
  end

  def siren_attributes
    extras = {:object_fields => self.object_fields.map(&:attributes)}
    super.merge extras
  end
end
