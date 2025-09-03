class CommentModerationJob < ApplicationJob
  queue_as :default

  def perform(comment)
    # Get all reports for this comment
    reports = comment.comment_reports.includes(:user)
    
    # If 3 or more reports, mark for moderation
    if reports.count >= 3
      # Log the moderation event
      Rails.logger.info "Comment #{comment.id} flagged for moderation with #{reports.count} reports"
      
      # In a real app, you might:
      # 1. Notify moderators
      # 2. Temporarily hide the comment
      # 3. Send email to admin
      # 4. Add to moderation queue
      
      # For now, we'll just mark it as needing review
      comment.update(is_deleted: true, content: '[Comment under review]')
      
      # Optional: Notify the comment author
      # CommentModerationNotificationJob.perform_later(comment.user, comment)
    end
  end
end
