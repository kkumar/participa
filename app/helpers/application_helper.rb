module ApplicationHelper


  # Like link_to but third parameter is an array of options for current_page?.
  def nav_menu_link_to name, icon, url, current_urls, html_options = {}
    html_options[:class] ||= ""
    html_options[:class] += " active" if current_urls.any? { |u| current_page?(u) }
    link_to(fa_icon(icon) + content_tag(:span, name), url, html_options)
  end

  def new_notifications_class
    # TODO: Implement check if there are any new notifications
    # If so, return "claim"
    ""
  end

  def current_lang? lang
    I18n.locale.to_s.downcase == lang.to_s.downcase
  end

  def current_lang_class lang
    if current_lang? lang
      "active"
    else
      ""
    end
  end

  def info_box &block
    content = with_output_buffer(&block)
    render partial: 'application/info', locals: { content: content }
  end

  # Renders an alert with given title,
  # text for close-button and content given in
  # a block.
  def alert_box title, close_text="", &block
    render_flash 'application/alert', title, close_text, &block
  end

  # Renders an error with given title,
  # text for close-button and content given in
  # a block.
  def error_box title, close_text="", &block
    render_flash 'application/error', title, close_text, &block
  end

  # Generalization from render_alert and render_error
  def render_flash partial_name, title, close_text="", &block
    content = with_output_buffer(&block)
    render partial: partial_name, locals: {title: title, content: content, close_text: close_text}
  end

  def field_notice_box
    render partial: 'application/form_field_notice'
  end

  def errors_in_form resource
    render partial: 'application/errors_in_form', locals: {resource: resource}
  end

  def steps_nav current_step, *steps_text
    render partial: 'application/steps_nav',
           locals: { first_step: steps_text[0],
                     second_step: steps_text[1],
                     third_step: steps_text[2],
                     steps_text: steps_text,
                     current_step: current_step }
  end

  def body_class signed_in, controller, action
    if !signed_in && controller == "sessions" && action == "new"
      "logged-out"
    else
      "signed-in"
    end
  end
end
