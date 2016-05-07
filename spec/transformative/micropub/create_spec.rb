require 'spec_helper'
require 'json'

describe "#create" do
  
  let(:response_headers) { { "Content-Type" => "application/json" } }
  let(:body) { { type: ['h-entry'] } }

  it 'should allow creating a simple post' do
    post '/micropub', body
    expect(last_response).to be_created
  end
  
  it 'should fail if no type is specified' do
    post '/micropub', {}
    expect(last_response.status).to eql(400)
  end
  
end
