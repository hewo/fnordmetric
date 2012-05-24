$: << ::File.expand_path("../lib/", __FILE__)
require "fnordmetric"

[:jura, :juridik, :revisor].each do |site|
FnordMetric.namespace site do

# ------------------------------------------------------------------
# Gauges
# ------------------------------------------------------------------

  gauge :document_per_product_monthly,
    :tick => 1.month.to_i,
    :title => "Monthly document views per product",
    :three_dimensional => true

  gauge :document_per_module_monthly,
    :tick => 1.month.to_i,
    :title => "Monthly document views per module",
    :three_dimensional => true

  gauge :search_query,
    :tick => 1.month.to_i,
    :title => "Search queries",
    :three_dimensional => true

  gauge :empty_searches,
    :tick => 1.month.to_i,
    :title => "Empty searches",
    :three_dimensional => true

  gauge :top_documents,
    :tick => 1.month.to_i,
    :title => "Top documents",
    :three_dimensional => true

  gauge :click_hit_number,
    :tick => 1.month.to_i,
    :title => "Clicked hit number",
    :three_dimensional => true

  gauge :note_refs_clicked, :tick => 1.day.to_i, :title => "Notes opened per day"

  gauge :search_regular, :tick => 1.month.to_i, :title => "Search normal"
  gauge :search_goto, :tick => 1.month.to_i, :title => "Search goto"
  gauge :superhit, :tick => 1.month.to_i, :title => "Superhits clicked"


# ---------------------------------------------------------------
# Event handling
# ---------------------------------------------------------------

  event :"document#chunk" do
    incr_field :document_per_product_monthly, data[:product]
    incr_field :document_per_module_monthly, data[:module]
    incr_field :top_documents, data[:title]
    if data[:rank]
      incr_field :click_hit_number, data[:rank].to_i
    end
    if data[:referrer].include?('/search') && !data[:url].include?('frt=')
      incr_field :click_hit_number, 0
    end
  end

  event :"api#document#note_ref" do
    incr :note_refs_clicked
  end

  event :"search#index" do
    incr_field :search_query, data[:query]
    if data[:goto]
      incr :search_goto
    else
      incr :search_regular
      if data[:hits].to_i == 0
        incr_field :empty_searches, data[:query]
      end
    end
  end

# ---------------------------------------------------------------
# Widgets
# ---------------------------------------------------------------

  widget 'Kgonline', {
    :title => "Top Products",
    :type => :toplist,
    :width => 100,
    :gauges => :document_per_product_monthly,
    :include_current => true
  }

  widget 'Kgonline', {
    :title => "Top modules",
    :type => :toplist,
    :width => 100,
    :gauges => :document_per_module_monthly,
    :include_current => true
  }

  widget 'Kgonline', {
    :title => "Top documents",
    :type => :toplist,
    :width => 100,
    :gauges => :top_documents,
    :include_current => true
  }

  widget 'Search', {
    :title => "Top searches",
    :type => :toplist,
    :width => 50,
    :gauges => :search_query,
    :include_current => true
  }

  widget 'Search', {
    :title => "Top empty searches",
    :type => :toplist,
    :width => 50,
    :gauges => :empty_searches,
    :include_current => true
  }

  widget 'Feature use', {
    :title => "Note refs clicked per day",
    :type => :timeline,
    :width => 100,
    :gauges => :note_refs_clicked,
    :include_current => true
  }

  widget 'Feature use', {
    :title => "Clicked hit number",
    :type => :bars,
    :width => 50,
    :order_by => :field,
    :gauges => :click_hit_number,
    :include_current => true
  }

  widget 'Feature use', {
    :title => "Search vs. goto",
    :type => :pie,
    :width => 50,
    :gauges => [:search_regular, :search_goto]
  }

  # -------------------------------------------------------

  gauge :events_per_minute, :tick => 60
  gauge :events_per_hour, :tick => 1.hour.to_i
  gauge :events_per_second, :tick => 1

  event :"*" do
    incr :events_per_minute
    incr :events_per_hour
    incr :events_per_second
  end

  widget 'TechStats', {
    :title => "Events per Minute",
    :type => :timeline,
    :width => 50,
    :gauges => :events_per_minute,
    :include_current => true,
    :autoupdate => 30
  }

  widget 'TechStats', {
    :title => "Events per Hour",
    :type => :timeline,
    :width => 50,
    :gauges => :events_per_hour,
    :include_current => true,
    :autoupdate => 30
  }

  widget 'TechStats', {
    :title => "Events/Second",
    :type => :timeline,
    :width => 50,
    :gauges => :events_per_second,
    :include_current => true,
    :plot_style => :areaspline,
    :autoupdate => 1
  }

end
end

FnordMetric.server_configuration = {
  :redis_url => "redis://localhost:6379/7",
  :redis_prefix => "fnordmetric",
  :inbound_stream => ["0.0.0.0", "1337"],
  :web_interface => ["0.0.0.0", "4242"],
  :start_worker => true,
  :print_stats => 3,

  # events that aren't processed after 2 min get dropped
  :event_queue_ttl => 120,

  # event data is kept for one month
  :event_data_ttl => 3600*24*30,

  # session data is kept for one month
  :session_data_ttl => 3600*24*30
}

#task :setup do
#  @fm_opts = {:web_interface => ["0.0.0.0", "2323"]} if ENV['DEV']
#end

FnordMetric.standalone
