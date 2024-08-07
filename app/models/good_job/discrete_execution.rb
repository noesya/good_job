# frozen_string_literal: true

module GoodJob # :nodoc:
  class DiscreteExecution < BaseRecord
    include ErrorEvents

    self.table_name = 'good_job_executions'
    self.implicit_order_column = 'created_at'

    belongs_to :execution, class_name: 'GoodJob::Execution', foreign_key: 'active_job_id', primary_key: 'active_job_id', inverse_of: :discrete_executions, optional: true
    belongs_to :job, class_name: 'GoodJob::Job', foreign_key: 'active_job_id', primary_key: 'active_job_id', inverse_of: :discrete_executions, optional: true

    scope :finished, -> { where.not(finished_at: nil) }

    alias_attribute :performed_at, :created_at

    def self.error_event_migrated?
      return true if columns_hash["error_event"].present?

      migration_pending_warning!
      false
    end

    def self.backtrace_migrated?
      return true if columns_hash["error_backtrace"].present?

      migration_pending_warning!
      false
    end

    def self.monotonic_duration_migrated?
      return true if columns_hash["duration"].present?

      migration_pending_warning!
      false
    end

    def number
      serialized_params.fetch('executions', 0) + 1
    end

    # Time between when this job was expected to run and when it started running
    def queue_latency
      created_at - scheduled_at
    end

    # Monotonic time between when this job started and finished
    def runtime_latency
      if self.class.monotonic_duration_migrated?
        duration
      elsif performed_at
        (finished_at || Time.current) - performed_at
      end
    end

    def last_status_at
      finished_at || created_at
    end

    def status
      if finished_at.present?
        if error.present? && job.finished_at.present?
          :discarded
        elsif error.present?
          :retried
        else
          :succeeded
        end
      else
        :running
      end
    end

    def display_serialized_params
      serialized_params.merge({
                                _good_job_execution: attributes.except('serialized_params'),
                              })
    end

    def filtered_error_backtrace
      Rails.backtrace_cleaner.clean(error_backtrace || [])
    end
  end
end
