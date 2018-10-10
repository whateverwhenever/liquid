# frozen_string_literal: true

module Liquid
  class Traversal
    def self.for(node, callbacks = Hash.new(proc {}))
      if defined?(node.class::Traversal)
        node.class::Traversal
      else
        self
      end.new(node, callbacks)
    end

    def initialize(node, callbacks)
      @node = node
      @callbacks = callbacks
    end

    def callback_for(*classes, &block)
      cb = block
      cb = ->(node, _) { block[node] } if block.arity.abs == 1
      cb = ->(_, _) { block[] } if block.arity.zero?
      classes.each { |klass| @callbacks[klass] = cb }
      self
    end

    def traverse(context = nil)
      children.map do |node|
        item, new_context = @callbacks[node.class][node, context]
        [
          item,
          Traversal.for(node, @callbacks).traverse(
            new_context.nil? ? context : new_context
          )
        ]
      end
    end

    protected

    def children
      @node.respond_to?(:nodelist) ? Array(@node.nodelist) : []
    end
  end
end
