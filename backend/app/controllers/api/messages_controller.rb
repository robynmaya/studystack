class Api::MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation
  before_action :authorize_participant!
  before_action :set_message, only: [:show, :destroy, :mark_as_read]

  # GET /api/conversations/:conversation_id/messages
  def index
    @messages = @conversation.messages
                 .includes(:sender)
                 .order(:created_at)
                 .page(params[:page])
                 .per(params[:per_page] || 50)

    render json: {
      messages: @messages.map { |msg| message_json(msg) },
      pagination: pagination_json(@messages)
    }
  end

  # GET /api/conversations/:conversation_id/messages/:id
  def show
    render json: { message: message_json(@message) }
  end

  # POST /api/conversations/:conversation_id/messages
  def create
    @message = @conversation.messages.build(message_params)
    @message.sender = current_user

    if @message.save
      # Update conversation timestamp
      @conversation.touch

      # Send notification to other participant
      other_participant = @conversation.other_participant(current_user)
      MessageNotificationJob.perform_later(@message, other_participant)

      render json: { message: message_json(@message) }, status: :created
    else
      render json: { errors: @message.errors }, status: :unprocessable_entity
    end
  end

  # PATCH /api/conversations/:conversation_id/messages/:id/read
  def mark_as_read
    if @message.sender != current_user && @message.mark_as_read!
      render json: { message: 'Message marked as read' }
    else
      render json: { error: 'Cannot mark own message as read' }, status: :bad_request
    end
  end

  # DELETE /api/conversations/:conversation_id/messages/:id
  def destroy
    if @message.sender == current_user
      @message.destroy
      render json: { message: 'Message deleted successfully' }
    else
      render json: { error: 'Can only delete your own messages' }, status: :forbidden
    end
  end

  # POST /api/conversations/:conversation_id/messages/mark_all_read
  def mark_all_read
    @conversation.mark_as_read_for(current_user)
    render json: { message: 'All messages marked as read' }
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def set_message
    @message = @conversation.messages.find(params[:id])
  end

  def authorize_participant!
    unless @conversation.creator == current_user || @conversation.subscriber == current_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def message_params
    params.require(:message).permit(:content, :message_type)
  end

  def message_json(message)
    {
      id: message.id,
      content: message.content,
      message_type: message.message_type,
      read_at: message.read_at,
      created_at: message.created_at,
      updated_at: message.updated_at,
      sender: {
        id: message.sender.id,
        full_name: message.sender.full_name,
        profile_image_url: message.sender.profile_image_url
      },
      is_own_message: message.sender == current_user,
      read: message.read?
    }
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
