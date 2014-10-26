# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class JoinRequestsNotificationsWorker
  @queue = :join_requests

  # Finds all join requests with pending notifications and sends them
  def self.perform
    request_notifications
    invite_notifications
    processed_request_notifications
  end

  # Goes through all activities for join requests created by admins inviting users to join a space
  # and enqueues a notification for each.
  def self.invite_notifications
    invites = RecentActivity.where trackable_type: 'JoinRequest', key: 'join_request.invite', notified: [nil,false]
    invites.each do |activity|
      Resque.enqueue(JoinRequestInviteNotificationWorker, activity.id)
    end
  end

  # Goes through all activities for join requests created by users to join a space and enqueues
  # a notification for each.
  def self.request_notifications
    requests = RecentActivity.where trackable_type: 'JoinRequest', key: 'join_request.request', notified: [nil,false]
    requests.each do |activity|
      Resque.enqueue(JoinRequestNotificationWorker, activity.id)
    end
  end

  # Goes through all activities for processed join requests for which the users have not been
  # notified yet, and enqueues a notification for each.
  def self.processed_request_notifications
    requests = RecentActivity.where trackable_type: 'Space', key: 'space.join', notified: [nil,false]
    requests = requests.all.reject { |req| req.parameters[:join_request_id].blank? }
    requests.each do |activity|
      Resque.enqueue(ProcessedJoinRequestNotificationWorker, activity.id)
    end
  end

end
