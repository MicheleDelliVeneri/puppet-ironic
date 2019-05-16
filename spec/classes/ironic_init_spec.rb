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
# Unit tests for ironic
#

require 'spec_helper'

describe 'ironic' do

  let :params do
    { :package_ensure              => 'present',
      :database_connection         => 'sqlite:////var/lib/ironic/ironic.sqlite',
      :database_max_retries        => 10,
      :database_idle_timeout       => 3600,
      :database_reconnect_interval => 10,
      :database_retry_interval     => 10,
      :purge_config                => false,
    }
  end

  shared_examples_for 'ironic' do

    context 'ironic setup' do
      it_configures 'a ironic base installation'
      it_configures 'with SSL disabled'
      it_configures 'with SSL enabled without kombu'
      it_configures 'with SSL enabled with kombu'
      it_configures 'with amqp_durable_queues disabled'
      it_configures 'with amqp_durable_queues enabled'
      it_configures 'without rabbit HA'
    end

    context 'ironic setup with rabbit HA' do
      before { params.merge!( :rabbit_ha_queues => true ) }
      it_configures 'with rabbit HA'
    end

    context 'with amqp messaging' do
      it_configures 'amqp support'
    end

    context 'with oslo messaging notifications' do
      it_configures 'oslo messaging notifications'
    end

  end

  shared_examples_for 'a ironic base installation' do

    it { is_expected.to contain_class('ironic::params') }

    it { is_expected.to contain_class('ironic::glance') }
    it { is_expected.to contain_class('ironic::neutron') }

    it 'installs ironic-common package' do
      is_expected.to contain_package('ironic-common').with(
        :ensure => 'present',
        :name   => platform_params[:common_package_name],
        :tag    => ['openstack', 'ironic-package'],
      )
    end

    it 'installs ironic-lib package' do
      is_expected.to contain_package('ironic-lib').with(
        :ensure => 'present',
        :name   => platform_params[:lib_package_name],
        :tag    => ['openstack', 'ironic-package'],
      )
    end

    it 'passes purge to resource' do
      is_expected.to contain_resources('ironic_config').with({
        :purge => false
      })
    end

    it 'configures credentials for rabbit' do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_failover_strategy').with_value('<SERVICE DEFAULT>')
    end

    it 'should perform default database configuration' do
      is_expected.to contain_ironic_config('database/connection').with_value(params[:database_connection])
      is_expected.to contain_ironic_config('database/max_retries').with_value(params[:database_max_retries])
      is_expected.to contain_ironic_config('database/connection_recycle_time').with_value(params[:database_idle_timeout])
      is_expected.to contain_ironic_config('database/retry_interval').with_value(params[:database_retry_interval])
    end

    it 'configures ironic.conf' do
      is_expected.to contain_ironic_config('DEFAULT/auth_strategy').with_value('keystone')
      is_expected.to contain_ironic_config('DEFAULT/my_ip').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('DEFAULT/executor_thread_pool_size').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('DEFAULT/rpc_response_timeout').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('DEFAULT/rpc_transport').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('DEFAULT/control_exchange').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('DEFAULT/transport_url').with_value('<SERVICE DEFAULT>').with_secret(true)
      is_expected.to contain_ironic_config('DEFAULT/default_resource_class').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('DEFAULT/notification_level').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ironic_config('DEFAULT/versioned_notifications_topics').with_value('<SERVICE DEFAULT>')
    end
  end

  shared_examples_for 'without rabbit HA' do
    it 'in ironic.conf' do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('<SERVICE DEFAULT>')
    end
  end

  shared_examples_for 'with rabbit HA' do
    it 'in ironic.conf' do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value(true)
    end
  end

  shared_examples_for 'with SSL enabled with kombu' do
    before do
      params.merge!(
        :rabbit_use_ssl     => true,
        :kombu_ssl_ca_certs => '/path/to/ssl/ca/certs',
        :kombu_ssl_certfile => '/path/to/ssl/cert/file',
        :kombu_ssl_keyfile  => '/path/to/ssl/keyfile',
        :kombu_ssl_version  => 'TLSv1'
      )
    end

    it { is_expected.to contain_oslo__messaging__rabbit('ironic_config').with(
      :rabbit_use_ssl     => params[:rabbit_use_ssl],
      :kombu_ssl_ca_certs => params[:kombu_ssl_ca_certs],
      :kombu_ssl_certfile => params[:kombu_ssl_certfile],
      :kombu_ssl_keyfile  => params[:kombu_ssl_keyfile],
      :kombu_ssl_version  => params[:kombu_ssl_version],
    )}
  end

  shared_examples_for 'with SSL enabled without kombu' do
    before do
      params.merge!(
        :rabbit_use_ssl     => true,
      )
    end

    it { is_expected.to contain_oslo__messaging__rabbit('ironic_config').with(
      :rabbit_use_ssl => params[:rabbit_use_ssl],
    )}
  end

  shared_examples_for 'with SSL disabled' do
    before do
      params.merge!(
        :rabbit_use_ssl     => false,
      )
    end

    it { is_expected.to contain_oslo__messaging__rabbit('ironic_config').with(
      :rabbit_use_ssl => params[:rabbit_use_ssl],
    )}
  end


  shared_examples_for 'with amqp_durable_queues disabled' do
    it { is_expected.to contain_ironic_config('oslo_messaging_rabbit/amqp_durable_queues').with_value('<SERVICE DEFAULT>') }
  end

  shared_examples_for 'with amqp_durable_queues enabled' do
    before do
      params.merge!( :amqp_durable_queues => true )
    end

    it { is_expected.to contain_ironic_config('oslo_messaging_rabbit/amqp_durable_queues').with_value(true) }
  end

  shared_examples_for 'oslo messaging notifications' do
    context 'with default parameters' do
      it { is_expected.to contain_ironic_config('oslo_messaging_notifications/transport_url').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_notifications/driver').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_notifications/topics').with_value('<SERVICE DEFAULT>') }
    end

    context 'with overridden notification parameters' do
      before { params.merge!(
        :notification_driver        => 'messagingv2',
        :notification_transport_url => 'http://host:port',
      ) }

      it { is_expected.to contain_ironic_config('oslo_messaging_notifications/transport_url').with_value('http://host:port') }
      it { is_expected.to contain_ironic_config('oslo_messaging_notifications/driver').with_value('messagingv2') }
      it { is_expected.to contain_ironic_config('oslo_messaging_notifications/topics').with_value('<SERVICE DEFAULT>') }
    end
  end

  shared_examples_for 'amqp support' do
    context 'with default parameters' do
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/server_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/broadcast_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/group_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/container_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/idle_timeout').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/trace').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_ca_file').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_cert_file').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_key_file').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_key_password').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/allow_insecure_clients').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_mechanisms').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_config_dir').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_config_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/username').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/password').with_value('<SERVICE DEFAULT>') }
    end

    context 'with overridden amqp parameters' do
      before { params.merge!(
        :amqp_idle_timeout  => '60',
        :amqp_trace         => true,
        :amqp_ssl_ca_file   => '/path/to/ca.cert',
        :amqp_ssl_cert_file => '/path/to/certfile',
        :amqp_ssl_key_file  => '/path/to/key',
        :amqp_username      => 'amqp_user',
        :amqp_password      => 'password',
      ) }

      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/server_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/broadcast_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/group_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/container_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/idle_timeout').with_value('60') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/trace').with_value('true') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_ca_file').with_value('/path/to/ca.cert') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_cert_file').with_value('/path/to/certfile') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/ssl_key_file').with_value('/path/to/key') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/allow_insecure_clients').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_mechanisms').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_config_dir').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/sasl_config_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/username').with_value('amqp_user') }
      it { is_expected.to contain_ironic_config('oslo_messaging_amqp/password').with_value('password') }
    end
  end

  shared_examples_for 'oslo messaging remote procedure call' do
    context 'with overridden rpc parameters' do
      before { params.merge!(
        :rpc_transport        => 'pigeons',
        :rpc_response_timeout => '3628800',
      ) }

      it { is_expected.to contain_ironic_config('DEFAULT/rpc_transport').with_value('pigeons') }
      it { is_expected.to contain_ironic_config('DEFAULT/rpc_response_timeout').with_value('3628800') }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts({
          :concat_basedir         => '/var/lib/puppet/concat',
          :fqdn                   => 'some.host.tld',
        }))
      end

      let :platform_params do
        case facts[:osfamily]
        when 'Debian'
          { :common_package_name => 'ironic-common',
            :lib_package_name    => 'python3-ironic-lib' }
        when 'RedHat'
          { :common_package_name => 'openstack-ironic-common',
            :lib_package_name    => 'python-ironic-lib' }
        end
      end

      it_behaves_like 'ironic'
    end
  end

end
