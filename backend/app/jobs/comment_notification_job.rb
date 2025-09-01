class CommentNotificationJob < ApplicationJob
  queue_as :default
  
  def perform(comment)
    # Notify document owner of new comment
    if comment.commentable_type == 'Document'
      document = comment.commentable
      return if document.user == comment.user # Don't notify self
      
      # In a real app, you would send email notifications, push notifications, etc.
      Rails.logger.info "New comment on document '#{document.title}' by #{comment.user.full_name}"
      
    # Notify parent comment author of reply
    elsif comment.commentable_type == 'Comment'
      parent_comment = comment.commentable
      return if parent_comment.user == comment.user # Don't notify self
      
      Rails.logger.info "New reply to comment by #{comment.user.full_name}"
    end
  end
end
