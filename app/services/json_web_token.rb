class JsonWebToken
  ALGORITHM = "HS256"
  TOKEN_TTL = 30.minutes

  def self.secret
    Rails.application.secret_key_base
  end

  def self.encode(user)
    now = Time.current.to_i

    JWT.encode(
      {
        sub: user.id.to_s,
        role: user.role,
        iat: now,
        exp: TOKEN_TTL.from_now.to_i
      },
      secret,
      ALGORITHM
    )
  end

  def self.decode(token)
    payload, = JWT.decode(
      token,
      secret,
      true,
      algorithm: ALGORITHM
    )

    payload
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
