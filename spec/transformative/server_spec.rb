require 'spec_helper'

describe Transformative::Server do
  
  it 'should allow accessing the homepage' do
    get '/'
    expect(last_response).to be_ok
  end
  
end