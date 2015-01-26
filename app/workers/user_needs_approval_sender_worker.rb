# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class UserNeedsApprovalSenderWorker
  @queue = :user_notifications

  # Sends a notification to all recipients in the array of ids `recipient_ids`
  # informing that the user with id `user_id` needs to be approved.
  def self.perform(user_id, recipient_ids)
    user = User.find(user_id)
    recipients = User.find(recipient_ids)

    recipients.each do |recipient|
      Resque.logger.info "Sending user needs approval email to #{recipient.inspect}, for user #{user.inspect}"
      AdminMailer.new_user_waiting_for_approval(recipient.id, user.id).deliver
    end

    user.update_attribute(:needs_approval_notification_sent_at, Time.now)
  end

end
