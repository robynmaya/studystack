require "test_helper"

class Api::MessagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @creator = users(:creator_user)
    @subscriber = users(:subscriber_user)
    @conversation = conversations(:creator_subscriber_conversation)
    @message = messages(:welcome_message)
    
    # Set authorization header for creator
    @auth_headers = { 'Authorization' => "Bearer #{generate_jwt_token(@creator)}" }
  end

  test "should get messages for conversation" do
    get api_conversation_messages_url(@conversation), headers: @auth_headers
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_includes response_data.keys, 'messages'
    assert_includes response_data.keys, 'pagination'
  end

  test "should create message in conversation" do
    message_params = {
      message: {
        content: "Hello, this is a test message!",
        message_type: "text"
      }
    }
    
    assert_difference('Message.count') do
      post api_conversation_messages_url(@conversation), 
           params: message_params, 
           headers: @auth_headers
    end
    
    assert_response :created
    response_data = JSON.parse(response.body)
    assert_equal "Hello, this is a test message!", response_data['message']['content']
    assert_equal @creator.id, response_data['message']['sender']['id']
  end

  test "should mark message as read" do
    # Switch to subscriber to mark creator's message as read
    subscriber_headers = { 'Authorization' => "Bearer #{generate_jwt_token(@subscriber)}" }
    
    patch mark_as_read_api_conversation_message_url(@conversation, @message), 
          headers: subscriber_headers
    
    assert_response :success
    @message.reload
    assert_not_nil @message.read_at
  end

  test "should not allow unauthorized access to conversation messages" do
    unauthorized_user = users(:another_user)
    unauthorized_headers = { 'Authorization' => "Bearer #{generate_jwt_token(unauthorized_user)}" }
    
    get api_conversation_messages_url(@conversation), headers: unauthorized_headers
    assert_response :unauthorized
  end

  test "should delete own message" do
    assert_difference('Message.count', -1) do
      delete api_conversation_message_url(@conversation, @message), headers: @auth_headers
    end
    
    assert_response :success
  end

  test "should not delete other user's message" do
    subscriber_headers = { 'Authorization' => "Bearer #{generate_jwt_token(@subscriber)}" }
    
    delete api_conversation_message_url(@conversation, @message), headers: subscriber_headers
    assert_response :forbidden
  end

  test "should mark all messages as read" do
    # Create a few unread messages
    3.times do |i|
      Message.create!(
        conversation: @conversation,
        sender: @creator,
        content: "Test message #{i}",
        message_type: "text"
      )
    end
    
    subscriber_headers = { 'Authorization' => "Bearer #{generate_jwt_token(@subscriber)}" }
    
    post mark_all_read_api_conversation_messages_url(@conversation), 
         headers: subscriber_headers
    
    assert_response :success
    
    # Check that all messages from creator are now marked as read
    unread_count = @conversation.messages.where(sender: @creator, read_at: nil).count
    assert_equal 0, unread_count
  end

  private

  def generate_jwt_token(user)
    # This would be your actual JWT generation logic
    # For testing, you might want to use a simpler approach
    JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
  end
end
