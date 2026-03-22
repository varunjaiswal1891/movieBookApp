import { createContext, useContext, useState, useCallback } from 'react'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    try {
      const stored = localStorage.getItem('user')
      return stored ? JSON.parse(stored) : null
    } catch {
      return null
    }
  })

  const loginUser = useCallback((userData) => {
    localStorage.setItem('token', userData.token)
    const userInfo = {
      id: userData.id,
      username: userData.username,
      email: userData.email,
      role: userData.role,
    }
    localStorage.setItem('user', JSON.stringify(userInfo))
    setUser(userInfo)
  }, [])

  const logoutUser = useCallback(() => {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    setUser(null)
  }, [])

  const isAdmin = user?.role === 'ADMIN'

  return (
    <AuthContext.Provider value={{ user, loginUser, logoutUser, isAdmin }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
