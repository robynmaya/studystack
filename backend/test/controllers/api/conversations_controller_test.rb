require "test_helper"

class Api::ConversationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @creator = users(:creator_user)
    @subscriber = users(:subscriber_user)
    @conversation = conversations(:creator_subscriber_conversation)
    
    # Set authorization header for creator
    @auth_headers = { 'Authorization' => "Bearer #{generate_jwt_token(@creator)}" }
  end

  test "should get conversations list" do
    get api_conversations_url, headers: @auth_headers
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_includes response_data.keys, 'conversations'
    assert_includes response_data.keys, 'pagination'
  end

  test "should show specific conversation" do
    get api_conversation_url(@conversation), headers: @auth_headers
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert_includes response_data.keys, 'conversation'
    assert_includes response_data.keys, 'messages'
    assert_equal @conversation.id, response_data['conversation']['id']
  end

  test "should create new conversation" do
    another_creator = users(:another_creator)
    
    conversation_params = {
      user_id: another_creator.id
    }
    
    assert_difference('Conversation.count') do
      post api_conversations_url, 
           params: conversation_params, 
           headers: @auth_headers
    end
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal another_creator.id, response_data['conversation']['other_participant']['id']
  end

  test "should not create conversation with non-creator" do
    regular_user = users(:regular_user)
    subscriber_headers = { 'Authorization' => "Bearer #{generate_jwt_token(@subscriber)}" }
    
    conversation_params = {
      user_id: regular_user.id
    }
    
    post api_conversations_url, 
         params: conversation_params, 
         headers: subscriber_headers
    
    assert_response :bad_request
  end

  test "should archive conversation" do
    patch archive_api_conversation_url(@conversation), headers: @auth_headers
    assert_response :success
    
    @conversation.reload
    assert @conversation.is_archived
  end

  test "should not allow unauthorized access to conversation" do
    unauthorized_user = users(:another_user)
    unauthorized_headers = { 'Authorization' => "Bearer #{generate_jwt_token(unauthorized_user)}" }
    
    get api_conversation_url(@conversation), headers: unauthorized_headers
    assert_response :unauthorized
  end

  test "should delete conversation" do
    assert_difference('Conversation.count', -1) do
      delete api_conversation_url(@conversation), headers: @auth_headers
    end
    
    assert_response :success
  end

  test "should filter archived conversations" do
    # Archive the conversation first
    @conversation.update!(is_archived: true)
    
    # Test showing archived conversations
    get api_conversations_url(archived: true), headers: @auth_headers
    assert_response :success
    
    response_data = JSON.parse(response.body)
    assert response_data['conversations'].any? { |conv| conv['id'] == @conversation.id }
  end

  test "should search conversations by participant name" do
    get api_conversations_url(search: @subscriber.full_name), headers: @auth_headers
    assert_response :success
    
    response_data = JSON.parse(response.body)
    found_conversation = response_data['conversations'].find { |conv| conv['id'] == @conversation.id }
    assert_not_nil found_conversation
  end

  private

  def generate_jwt_token(user)
    # This would be your actual JWT generation logic
    JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
  end
end
