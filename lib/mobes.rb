class Mobes
  include Cinch::Plugin

  match 'mobes'

  def execute m
    m.reply 'http://cl.ly/image/2f1l3D2S0825'
  end
end
