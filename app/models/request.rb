class Request < ApplicationRecord
  belongs_to :user
  belongs_to :viaje
  validate :pending_Score, on:[:create]
  validate :tarjeta
  validate :vencimiento
  before_create :iniciar

  def iniciar
    self.state||=0
    self.passengerScore||=0
    self.driverScore||=0
  end

  def pending_Score
    unless User.current.pending_califications
      errors.add(:base, 'tienes puntuaciones pendientes')
    end
  end

  def tarjeta
    unless User.current.has_credit_card
      errors.add(:base, 'debes registrar tu tarjeta de credito')
    end
  end

  def vencimiento
    unless User.current.can_Pay(viaje)
      errors.add(:base, 'tu tarjeta de credito caduca antes del viaje')
    end
  end

  def estado
    if state==0
      m="pendiente"
    else
      if state==1
        m="aceptada"
      else
        if state==2
          m="rechazada"
        else
          m = "cancelada"
        end
      end
    end
  m
  end

  def isPending
    @state == 0
  end

  def isAccepted
    state == 1
  end

  def isRefused
    state == 2
  end

  def isCanceled
    state == 3
  end

  def cancel(usuario)
    if usuario=self.user
      self.update(:passengerScore=>-1,:state=>3)
    else
      self.update(:driverScore=>-1,:state=>3)
    end
  end

  def change(code)
    case code
    when 1
      self.accept
    when 2
      self.refuse
    when 3
      self.cancel(User.current)
    end
  end

  def accept
    if viaje.asientos_libres>0
      self.update(:state=>1)
      self.viaje.add_Pasajero(self.user)
    end
  end

  def refuse
    self.update(:state=>2)
  end
end
