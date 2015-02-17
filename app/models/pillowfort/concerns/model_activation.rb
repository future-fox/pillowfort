require 'pillowfort/model_context'
require 'pillowfort/token_generator'
require 'pillowfort/model_finder'

module Pillowfort
  module Concerns::ModelActivation
    extend ActiveSupport::Concern

    included do
      Pillowfort::ModelContext.model_class = self

      # non-activated resource
      validates :activation_token, presence: true, uniqueness: true
      validates :activation_token_expires_at, presence: true, unless: :activated_at
      validates :activated_at, absence: true, if: :activation_token_expires_at

      # Activated resource
      validates :activated_at, presence: true, unless: :activation_token_expires_at
      validates :activation_token_expires_at, absence: true, if: :activated?

      def create_activation_token(expiry: nil)
        expiry ||= 1.hour.from_now
        self.activation_token = generate_activation_token
        self.activation_token_expires_at = expiry
      end

      def create_activation_token!(expiry: nil)
        create_activation_token(expiry)
        save validate: false
      end

      def activation_token_expired?
        if activation_token_expires_at
          activation_token_expires_at <= Time.now
        else
          true
        end
      end

      def activated?
        !!activated_at
      end

      def activate!
        update_columns \
          activated_at: Time.now,
          activation_token_expires_at: nil
      end

      private

      def generate_activation_token
        resource_class = self.class
        loop do
          token = resource_class.friendly_token
          break token unless resource_class.where(activation_token: token).first
        end
      end
    end

    module ClassMethods
      include Pillowfort::TokenGenerator
      include Pillowfort::ModelFinder

      def find_and_activate(email, token)
        return false if email.blank? || token.blank?

        transaction do
          if resource = find_by_email_case_insensitive(email)
            if resource.activation_token_expired?
              return false
            else
              if secure_compare(resource.activation_token, token)
                resource.activate!
                yield resource if block_given?
              end
            end
          end
        end
      end
    end
  end
end
