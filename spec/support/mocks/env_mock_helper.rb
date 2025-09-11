# frozen_string_literal: true

module EnvMockHelper
  def stub_env(**kwargs)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original

    kwargs.each do |key, value|
      allow(ENV).to receive(:fetch).with(key.to_s, nil).and_return(value)
      allow(ENV).to receive(:[]).with(key.to_s).and_return(value)
    end
  end
end
