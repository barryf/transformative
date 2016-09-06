require 'spec_helper'
require 'json'

describe Transformative::Micropub::Create do
  let(:response_headers) { { "Content-Type" => "application/json" } }
  let(:body) { { type: ['h-entry'] } }

  context "#create" do
    context "when creating a post" do
      it 'should allow creating a simple post' do
        post '/micropub', body
        expect(last_response).to be_created
      end
      it 'should fail with 400 if no type is specified' do
        post '/micropub'
        expect(last_response.status).to eql(400)
      end
    end
  end

end
