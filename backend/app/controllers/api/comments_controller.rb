class Api::CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_comment, only: [:show, :update, :destroy]
  before_action :authorize_owner!, only: [:update, :destroy]
  before_action :set_commentable, only: [:index, :create]
  
  # GET /api/documents/:document_id/comments
  # GET /api/comments/:comment_id/replies
  def index
    @comments = @commentable.comments.includes(:user, :replies)
    
    # For documents, only show top-level comments unless requesting replies
    if @commentable.is_a?(Document)
      @comments = @comments.top_level unless params[:include_replies] == 'true'
    end
    
    # Apply sorting
    case params[:sort_by]
    when 'recent'
      @comments = @comments.order(created_at: :desc)
    when 'oldest'
      @comments = @comments.order(created_at: :asc)
    when 'helpful'
      @comments = @comments.joins(:comment_votes).group('comments.id').order('COUNT(comment_votes.id) DESC')
    else
      @comments = @comments.order(created_at: :desc)
    end
    
    # Pagination
    @comments = @comments.page(params[:page]).per(params[:per_page] || 20)
    
    render json: {
      comments: @comments.map { |comment| comment_json(comment, include_replies: params[:include_replies] == 'true') },
      pagination: pagination_json(@comments)
    }
  end
  
  # GET /api/comments/:id
  def show
    render json: { comment: comment_json(@comment, detailed: true, include_replies: true) }
  end
  
  # POST /api/documents/:document_id/comments
  # POST /api/comments/:comment_id/replies
  def create
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user
    
    if @comment.save
      # Notify document owner or parent comment author
      CommentNotificationJob.perform_later(@comment)
      
      render json: { comment: comment_json(@comment) }, status: :created
    else
      render json: { errors: @comment.errors }, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /api/comments/:id
  def update
    if @comment.update(comment_params.slice(:content))
      @comment.update(edited_at: Time.current)
      render json: { comment: comment_json(@comment) }
    else
      render json: { errors: @comment.errors }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/comments/:id
  def destroy
    @comment.destroy
    head :no_content
  end
  
  # POST /api/comments/:id/vote
  def vote
    @comment = Comment.find(params[:id])
    vote_type = params[:vote_type] # 'helpful' or 'not_helpful'
    
    unless ['helpful', 'not_helpful'].include?(vote_type)
      return render json: { error: 'Invalid vote type' }, status: :bad_request
    end
    
    # Check if user already voted on this comment
    existing_vote = @comment.comment_votes.find_by(user: current_user)
    
    if existing_vote
      if existing_vote.vote_type == vote_type
        # Remove vote if clicking same vote type
        existing_vote.destroy
        vote_removed = true
      else
        # Update vote type
        existing_vote.update!(vote_type: vote_type)
        vote_removed = false
      end
    else
      # Create new vote
      @comment.comment_votes.create!(user: current_user, vote_type: vote_type)
      vote_removed = false
    end
    
    render json: {
      comment_id: @comment.id,
      vote_type: vote_removed ? nil : vote_type,
      helpful_count: @comment.helpful_votes_count,
      not_helpful_count: @comment.not_helpful_votes_count
    }
  end
  
  # POST /api/comments/:id/report
  def report
    @comment = Comment.find(params[:id])
    reason = params[:reason]
    
    unless ['spam', 'inappropriate', 'harassment', 'other'].include?(reason)
      return render json: { error: 'Invalid report reason' }, status: :bad_request
    end
    
    # Check if user already reported this comment
    existing_report = @comment.comment_reports.find_by(user: current_user)
    
    if existing_report
      return render json: { error: 'Comment already reported' }, status: :conflict
    end
    
    @comment.comment_reports.create!(
      user: current_user,
      reason: reason,
      description: params[:description]
    )
    
    # Queue moderation review if enough reports
    if @comment.comment_reports.count >= 3
      CommentModerationJob.perform_later(@comment)
    end
    
    render json: { message: 'Comment reported successfully' }
  end
  
  private
  
  def set_comment
    @comment = Comment.find(params[:id])
  end
  
  def set_commentable
    if params[:document_id]
      @commentable = Document.find(params[:document_id])
    elsif params[:comment_id]
      @commentable = Comment.find(params[:comment_id])
    else
      render json: { error: 'Invalid commentable' }, status: :bad_request
    end
  end
  
  def authorize_owner!
    unless @comment.user == current_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
  
  def comment_params
    params.require(:comment).permit(:content)
  end
  
  def comment_json(comment, detailed: false, include_replies: false)
    json = {
      id: comment.id,
      content: comment.content,
      created_at: comment.created_at,
      updated_at: comment.updated_at,
      edited_at: comment.edited_at,
      helpful_votes_count: comment.helpful_votes_count,
      not_helpful_votes_count: comment.not_helpful_votes_count,
      replies_count: comment.replies.count,
      user: {
        id: comment.user.id,
        full_name: comment.user.full_name,
        profile_image_url: comment.user.profile_image_url
      }
    }
    
    # Add user's vote if authenticated
    if current_user
      user_vote = comment.comment_votes.find_by(user: current_user)
      json[:user_vote] = user_vote&.vote_type
      json[:can_edit] = comment.user == current_user
      json[:can_delete] = comment.user == current_user
    end
    
    # Add commentable info for detailed view
    if detailed
      json[:commentable] = {
        type: comment.commentable_type,
        id: comment.commentable_id
      }
      
      if comment.commentable_type == 'Document'
        json[:commentable][:title] = comment.commentable.title
      end
    end
    
    # Include replies if requested
    if include_replies && comment.replies.any?
      json[:replies] = comment.replies.includes(:user).map { |reply| comment_json(reply) }
    end
    
    json
  end
  
  def pagination_json(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end
