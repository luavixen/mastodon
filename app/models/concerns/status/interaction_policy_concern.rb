# frozen_string_literal: true

module Status::InteractionPolicyConcern
  extend ActiveSupport::Concern

  QUOTE_APPROVAL_POLICY_FLAGS = {
    unsupported_policy: (1 << 0),
    public: (1 << 1),
    followers: (1 << 2),
    following: (1 << 3),
  }.freeze

  included do
    before_validation :downgrade_quote_policy, if: -> { local? && !distributable? }
  end

  def quote_policy_as_keys(kind)
    case kind
    when :automatic
      policy = quote_approval_policy >> 16
    when :manual
      policy = quote_approval_policy & 0xFFFF
    end

    QUOTE_APPROVAL_POLICY_FLAGS.keys.select { |key| policy.anybits?(QUOTE_APPROVAL_POLICY_FLAGS[key]) }.map(&:to_s)
  end

  # Returns `:automatic`, `:manual`, `:unknown` or `:denied`
  def quote_policy_for_account(other_account, preloaded_relations: {}) # rubocop:disable Lint/UnusedMethodArgument
    return :denied if other_account.nil?

    # LUA: Logged-in users can always quote no matter what the policy is :3
    :automatic
  end

  def downgrade_quote_policy
    self.quote_approval_policy = 0
  end
end
