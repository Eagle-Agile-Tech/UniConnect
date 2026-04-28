import React, { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is logged in on app start
    const storedUser = localStorage.getItem('user');
    if (storedUser) {
      setUser(JSON.parse(storedUser));
    }
    setLoading(false);
  }, []);

  const login = async ({ email, password }) => {
    // Simulate API call
    setLoading(true);
    try {
      // For demo purposes, accept any email/password
      // In real app, make API call here
      const userData = { email, name: email.split('@')[0] };
      setUser(userData);
      localStorage.setItem('user', JSON.stringify(userData));
    } catch (error) {
      throw new Error('Invalid credentials');
    } finally {
      setLoading(false);
    }
  };

  const signup = async ({ name, email, password }) => {
    // Simulate API call
    setLoading(true);
    try {
      // For demo purposes, create user
      // In real app, make API call here
      const userData = { name, email };
      setUser(userData);
      localStorage.setItem('user', JSON.stringify(userData));
    } catch (error) {
      throw new Error('Signup failed');
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('user');
  };

  const value = {
    user,
    login,
    signup,
    logout,
    loading
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};