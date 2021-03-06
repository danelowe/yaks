module Yaks
  class Attributes < Module
    attr_reader :defaults, :names

    def initialize(*attrs)
      @defaults   = attrs.last.instance_of?(Hash) ? attrs.pop : {}
      @names = (attrs + @defaults.keys).uniq
    end

    def add(*attrs)
      defaults = attrs.last.instance_of?(Hash) ? attrs.pop : {}
      self.class.new(*[*(names+attrs), @defaults.merge(defaults)])
    end

    def remove(*attrs)
      self.class.new(*[*(names-attrs), @defaults.reject {|k| attrs.include?(k) }])
    end

    def included(descendant)
      descendant.module_exec(self) do |this|
        include InstanceMethods,
                Anima.new(*this.names),
                Anima::Update

        alias with update

        define_singleton_method(:attributes) { this }
      end
    end

    module InstanceMethods
      def initialize(attributes = {})
        super(self.class.attributes.defaults.merge(attributes))
      end

      def append_to(type, *objects)
        with(type => instance_variable_get("@#{type}") + objects)
      end

      def to_h_compact
        defaults = self.class.attributes.defaults
        to_h.reject do |attr, value|
          value.equal?(defaults[attr])
        end
      end

      def pp
        indent = ->(str) { str.lines.map {|l| "  #{l}"}.join }
        format = ->(val) { val.respond_to?(:pp) ? val.pp : val.inspect }

        values   = to_h_compact

        fmt_attrs = values.map do |attr, value|
          fmt_val = case value
                    when Array
                      if value.inspect.length < 50
                        "[#{value.map(&format).join(", ")}]"
                      else
                        "[\n#{indent[value.map(&format).join(",\n")]}\n]"
                      end
                    else
                      format[value]
                    end
          "#{attr}: #{fmt_val}"
        end

        fmt_attrs_str = fmt_attrs.join(", ")

        if fmt_attrs_str.length > 50
          fmt_attrs_str = fmt_attrs.join(",\n")
        end

        if fmt_attrs_str =~ /\n/
          fmt_attrs_str = "\n#{indent[fmt_attrs_str]}\n"
        end
        "#{self.class.name}.new(#{fmt_attrs_str})"
      end
    end
  end
end
