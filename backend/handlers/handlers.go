package handlers

import "strconv"

// Helper function used across handlers
func atoiHelper(s string) uint {
	i, _ := strconv.Atoi(s)
	return uint(i)
}
