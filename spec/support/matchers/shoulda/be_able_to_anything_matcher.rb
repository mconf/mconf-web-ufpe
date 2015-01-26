# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

# Check if the subject can(not) do anything to the target.
# Exists because "should be_able_to(:manage, target)" guarantees that
# a user CAN do anything, but "should_not be_able_to(:manage, target)"
# does not guarantee that a user cannot to anything, only that he
# cannot :manage the target (but he could be able to :read it, for instance).
# Only makes send when used with "should_not".
#
# Examples:
#   it { should_not be_able_to_do_anything_to(object) }
#   it { should_not be_able_to_do_anything_to(object).except(:read) }
#
# If your target object has custom actions, you have to set them first, otherwise
# they won't be considered! You can do something like this in your :
#
#   module Helpers
#     module ClassMethods
#       # Sets the custom actions that should also be checked by
#       # the matcher BeAbleToDoAnythingToMatcher
#       def set_custom_ability_actions(actions)
#         before(:each) do
#           Shoulda::Matchers::ActiveModel::BeAbleToDoAnythingToMatcher.custom_actions = actions
#         end
#       end
#     end
#   end
#
#   # in your `spec_helper.rb`:
#   config.extend Helpers::ClassMethods
#
#   # in your specs:
#   set_custom_ability_actions([:play, :other_custom_action])
#
module Shoulda
  module Matchers
    module ActiveModel # :nodoc

      def be_able_to_do_anything_to(target)
        BeAbleToDoAnythingToMatcher.new(target)
      end

      class BeAbleToDoAnythingToMatcher < ValidationMatcher # :nodoc:

        # all RESTful actions in Rails plus the aliases defined by CanCan,
        # see https://github.com/ryanb/cancan/wiki/Action-Aliases
        cattr_accessor 'actions'
        @@actions = [:read, :update, :create, :destroy, :manage, :show, :index, :edit, :new]

        cattr_accessor 'custom_actions'
        @@custom_actions = []

        def initialize(target)
          @target = target
          @exceptions = []
        end

        def except(actions)
          @exceptions = [actions].flatten
          self
        end

        def matches?(subject)
          @subject = subject

          actions = @@actions + @@custom_actions
          @can = actions.select {|a| subject.can?(a, @target)}

          # expand default aliases defined by cancan
          @exceptions.push(:show, :index) if @exceptions.include?(:read)
          @exceptions.push(:new) if @exceptions.include?(:create)
          # this aliases is standard in cancan, but we removed it on mconf-web
          # @exceptions.push(:edit) if @exceptions.include?(:update)

          # returning false means should_not is successful
          !(@can.sort.uniq == @exceptions.sort.uniq)
        end

        def description
          desc = "be able to do anything to the object"
          unless @exceptions.empty?
            desc += " except #{@exceptions}"
          end
          desc
        end

        def failure_message
          "Don't use this matcher with 'should'. You might have to replace it by 'be_able_to(:manage, target)'"
        end

        def failure_message_for_should_not
          m = "Expected #{@subject.class.name} not to be able to do anything with '#{@target}'"
          unless @exceptions.empty?
            m += " except #{@exceptions},"
          end
          m += " but it can #{@can}"
          m
        end

      end
    end
  end
end
