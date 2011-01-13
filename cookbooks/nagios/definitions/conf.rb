define :nagios_conf, :variables => {}, :subdir => true, :action => :create, :mode => "0644" do
  subdir = if params[:subdir]
             "objects/"
           else
             ""
           end

  service = if params[:name] == "nrpe"
              "nrpe"
            else
              "nagios"
            end

  params[:template] ||= "#{params[:name]}.cfg.erb"

  template "/etc/nagios/#{subdir}#{params[:name]}.cfg" do
    source params[:template]
    owner "nagios"
    group "nagios"
    mode params[:mode]
    variables params[:variables]
    notifies :restart, resources(:service => service), :delayed
    action params[:action]
  end
end