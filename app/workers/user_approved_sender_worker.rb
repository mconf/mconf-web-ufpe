# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class UserApprovedSenderWorker
  @queue = :user_notifications

  # Sends a notification to the user with id `user_id` that he was approved.
  def self.perform(user_id)
    user = User.find(user_id)

    Resque.logger.info "Sending user approved email to #{user.inspect}"
    AdminMailer.new_user_approved(user.id).deliver

    user.update_attribute(:approved_notification_sent_at, Time.now)
  end

end
