module Pixiurge
  # Exceptions for Pixiurge
  #
  # @since 0.2.0
  module Errors
    # All Pixiurge errors descend from this type.
    #
    # @since 0.2.0
    class Exception < RuntimeError; end

    # Something is wrong with a subscribed message type. The name
    # might contain illegal characters or the message may already have
    # a registered handler.
    #
    # @since 0.2.0
    class MessageTypeError < Exception; end
  end
end
