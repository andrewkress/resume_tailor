ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

unless Object.method_defined?(:stub)
  class Object
    def stub(name, value, &block)
      original_method = method(name)

      define_singleton_method(name) do |*args, **kwargs, &method_block|
        if value.respond_to?(:call)
          value.call(*args, **kwargs, &method_block)
        else
          value
        end
      end

      block.call
    ensure
      define_singleton_method(name, original_method)
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    private

    def stub(**methods)
      Object.new.tap do |object|
        methods.each do |name, implementation|
          object.define_singleton_method(name) do |*args, **kwargs, &block|
            if implementation.respond_to?(:call)
              implementation.call(*args, **kwargs, &block)
            else
              implementation
            end
          end
        end
      end
    end
  end
end
