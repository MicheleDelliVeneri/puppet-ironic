#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for ironic::drivers::ipmi class
#

require 'spec_helper'

describe 'ironic::drivers::ipmi' do

  let :default_params do
    {}
  end

  let :params do
    {}
  end

  shared_examples_for 'ironic ipmi driver' do
    let :p do
      default_params.merge(params)
    end

    it 'configures ironic.conf' do
      is_expected.to contain_ironic_config('ipmi/command_retry_timeout').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('ipmi/min_command_interval').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('ipmi/debug').with_value('<SERVICE DEFAULT>')
    end

    context 'when overriding parameters' do
      before do
        params.merge!(
          :command_retry_timeout => '50',
          :min_command_interval  => '5',
          :debug                 => true,
        )
      end
      it 'should replace default parameter with new value' do
        is_expected.to contain_ironic_config('ipmi/command_retry_timeout').with_value('50')
        is_expected.to contain_ironic_config('ipmi/min_command_interval').with_value('5')
        is_expected.to contain_ironic_config('ipmi/debug').with_value(true)
      end
    end

  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ironic ipmi driver'

    end
  end

end
