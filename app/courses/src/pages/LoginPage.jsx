import React, { useState } from "react";
import "./LoginPage.css";
import loginImage from "../assets/images/login1.png";

export default function LoginPage({ onLogin, error }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();
    if (onLogin) {
      onLogin(email, password);
    }
  };

  return (
    <div
      className="container"
      style={{ backgroundImage: `url(${loginImage})` }}
    >
      <div className="overlay" />
      <div className="login-card">
        <h2>Welcome</h2>

        <form onSubmit={handleSubmit}>
          <div className="input-group">
            <label>Email</label>
            <input
              type="email"
              placeholder="Enter your email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          <div className="input-group">
            <label>Password</label>
            <input
              type="password"
              placeholder="Enter your password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          {error ? <p className="error">{error}</p> : null}

          <button type="submit">Login</button>
        </form>
      </div>
    </div>
  );
}
