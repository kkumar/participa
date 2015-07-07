class UsersMailer < ActionMailer::Base
  layout "email"
  default from: Rails.application.secrets[:default_from_email]

  def microcredit_email(microcredit, loan)
    @microcredit = microcredit
    @loan = loan
    attachments['IngresoMicrocreditosPodemos.pdf'] = WickedPdf.new.pdf_from_string(render_to_string pdf: 'IngresoMicrocreditosPodemos.pdf', template: 'microcredit/email_guide.pdf.erb', encoding: "UTF-8")
    mail(from: '"Podemos" <microcreditos@podemos.info>', to: @loan.email, subject: 'Confirmación microcréditos Podemos')
  end
end
