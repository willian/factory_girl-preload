module FactoryGirl
  module Preload
    module Helpers
      def self.extended(base)
        included(base)
      end

      def self.included(base)
        Dir[Rails.application.root.join("app/models/**/*.rb")].each do |file|
          require_dependency file
        end if defined?(Rails)

        create_fixtures_method_for(ActiveRecord::Base.descendants) if defined?(ActiveRecord)
        create_fixtures_method_for(Mongoid.models) if defined?(Mongoid)
      end

      def factory(name, model = nil, &block)
        if block_given?
          factory_set(name, &block)
        else
          factory_get(name, model)
        end
      end

      private
      def self.create_fixtures_method_for(models)
        models.each do |model|
          method_name = model.name.underscore.gsub("/", "_").pluralize

          class_eval <<-RUBY, __FILE__, __LINE__
            def #{method_name}(name)
              factory(name, ::#{model})
            end
          RUBY
        end
      end

      def factory_get(name, model)
        factory = Preload.factories[model.name][name]
        if factory.blank? && Preload.factories[model.name].has_key?(name)
          factory = Preload.factories[model.name][name] = model.find(Preload.record_ids[model.name][name])
        end
        raise "Couldn't find #{name.inspect} factory for #{model.name.inspect} model" unless factory
        factory
      end

      def create(name, attrs = {})
        FactoryGirl.create(name, attrs)
      end

      def factory_set(name, &block)
        record = instance_eval(&block)
        Preload.factories[record.class.name] ||= {}
        Preload.factories[record.class.name][name.to_sym] = record

        Preload.record_ids[record.class.name] ||= {}
        Preload.record_ids[record.class.name][name.to_sym] = record.id
      end
    end
  end
end
