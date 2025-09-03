class Api::ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [:show, :destroy, :archive]
  before_action :authorize_participant!, only: [:show, :destroy, :archive]

  # GET /api/conversations
  def index
    @conversations = current_user.creator_conversations
                      .or(current_user.subscriber_conversations)
                      .includes(:creator, :subscriber, :messages)
                      .order('conversations.updated_at DESC')

    # Apply filters
    @conversations = @conversations.active unless params[:archived] == 'true'
    @conversations = @conversations.archived if params[:archived] == 'true'

    # Search by participant name
    if params[:search].present?
      @conversations = @conversations.joins(:creator, :subscriber)
                        .where(
                          "users.full_name ILIKE ? OR subscribers_conversations.full_name ILIKE ?",
                          "%#{params[:search]}%", "%#{params[:search]}%"
                        )
    end

    @conversations = @conversations.page(params[:page]).per(params[:per_page] || 20)

    render json: {
      conversations: @conversations.map { |conv| conversation_json(conv) },
      pagination: pagination_json(@conversations)
    }
  end

  # GET /api/conversations/:id
  def show
    @messages = @conversation.messages
                 .includes(:sender)
                 .order(:created_at)
                 .page(params[:page])
                 .per(params[:per_page] || 50)

    # Mark messages as read for current user
    @conversation.mark_as_read_for(current_user)

    render json: {
      conversation: conversation_json(@conversation, detailed: true),
      messages: @messages.map { |msg| message_json(msg) },
      pagination: pagination_json(@messages)
    }
  end

  # POST /api/conversations
  def create
    @other_user = User.find(params[:user_id])

    unless @other_user.creator? || current_user.creator?
      return render json: { error: 'At least one participant must be a creator' }, status: :bad_request
    end

    # Determine who is creator and who is subscriber
    if current_user.creator? && @other_user.creator?
      # Both creators - use current user as creator
      creator = current_user
      subscriber = @other_user
    elsif current_user.creator?
      creator = current_user
      subscriber = @other_user
    else
      creator = @other_user
      subscriber = current_user
    end

    @conversation = Conversation.find_or_create_by(
      creator: creator,
      subscriber: subscriber
    )

    render json: { conversation: conversation_json(@conversation) }
  end

  # PATCH /api/conversations/:id/archive
  def archive
    if @conversation.update(is_archived: true)
      render json: { message: 'Conversation archived successfully' }
    else
      render json: { errors: @conversation.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /api/conversations/:id
  def destroy
    @conversation.destroy
    render json: { message: 'Conversation deleted successfully' }
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  def authorize_participant!
    unless @conversation.creator == current_user || @conversation.subscriber == current_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def conversation_json(conversation, detailed: false)
    other_participant = conversation.other_participant(current_user)
    last_message = conversation.last_message

    json = {
      id: conversation.id,
      is_archived: conversation.is_archived,
      created_at: conversation.created_at,
      updated_at: conversation.updated_at,
      other_participant: {
        id: other_participant.id,
        full_name: other_participant.full_name,
        profile_image_url: other_participant.profile_image_url,
        is_creator: other_participant.creator?
      },
      unread_count: conversation.unread_count_for(current_user)
    }

    if last_message
      json[:last_message] = {
        id: last_message.id,
        content: last_message.content,
        message_type: last_message.message_type,
        created_at: last_message.created_at,
        sender_id: last_message.sender_id
      }
    end

    json
  end

  def message_json(message)
    {
      id: message.id,
      content: message.content,
      message_type: message.message_type,
      read_at: message.read_at,
      created_at: message.created_at,
      sender: {
        id: message.sender.id,
        full_name: message.sender.full_name,
        profile_image_url: message.sender.profile_image_url
      },
      is_own_message: message.sender == current_user
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
