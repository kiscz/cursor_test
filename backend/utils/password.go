package utils

import (
	"log"
	"strings"
	"golang.org/x/crypto/bcrypt"
)

func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

func CheckPassword(password, hash string) bool {
	log.Printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Printf("[DEBUG-PASSWORD] CheckPassword called")
	log.Printf("[DEBUG-PASSWORD]")
	log.Printf("[DEBUG-PASSWORD] 1. Input Parameters:")
	log.Printf("[DEBUG-PASSWORD]    password = '%s' (len=%d)", password, len(password))
	log.Printf("[DEBUG-PASSWORD]    hash     = '%s' (len=%d)", hash, len(hash))
	log.Printf("[DEBUG-PASSWORD]")
	
	// 检查hash格式
	log.Printf("[DEBUG-PASSWORD] 2. Hash Format Validation:")
	if len(hash) != 60 {
		log.Printf("[DEBUG-PASSWORD]    ⚠️  Hash length is %d, expected 60", len(hash))
	} else {
		log.Printf("[DEBUG-PASSWORD]    ✅ Hash length correct (60)")
	}
	
	if strings.HasPrefix(hash, "$2a$") {
		log.Printf("[DEBUG-PASSWORD]    ✅ Hash prefix: $2a$ (bcrypt)")
	} else if strings.HasPrefix(hash, "$2b$") {
		log.Printf("[DEBUG-PASSWORD]    ✅ Hash prefix: $2b$ (bcrypt)")
	} else if strings.HasPrefix(hash, "$2y$") {
		log.Printf("[DEBUG-PASSWORD]    ✅ Hash prefix: $2y$ (bcrypt)")
	} else {
		log.Printf("[DEBUG-PASSWORD]    ❌ Invalid hash prefix: %s", hash[:4])
	}
	
	// 提取cost
	if len(hash) >= 7 {
		costStr := hash[4:6]
		log.Printf("[DEBUG-PASSWORD]    Cost: %s", costStr)
	}
	
	log.Printf("[DEBUG-PASSWORD]")
	log.Printf("[DEBUG-PASSWORD] 3. Converting to bytes:")
	hashBytes := []byte(hash)
	passwordBytes := []byte(password)
	log.Printf("[DEBUG-PASSWORD]    hashBytes[0:10]     = %v", hashBytes[0:10])
	log.Printf("[DEBUG-PASSWORD]    hashBytes[50:60]    = %v", hashBytes[50:60])
	log.Printf("[DEBUG-PASSWORD]    passwordBytes       = %v", passwordBytes)
	log.Printf("[DEBUG-PASSWORD]")
	
	log.Printf("[DEBUG-PASSWORD] 4. Calling bcrypt.CompareHashAndPassword(hashBytes, passwordBytes)...")
	log.Printf("[DEBUG-PASSWORD]    This is a third-party library function - we can't see inside it")
	log.Printf("[DEBUG-PASSWORD]    Waiting for result...")
	
	err := bcrypt.CompareHashAndPassword(hashBytes, passwordBytes)
	
	log.Printf("[DEBUG-PASSWORD]")
	log.Printf("[DEBUG-PASSWORD] 5. bcrypt.CompareHashAndPassword returned:")
	if err == nil {
		log.Printf("[DEBUG-PASSWORD]    ✅✅✅ SUCCESS! err = nil")
		log.Printf("[DEBUG-PASSWORD]    Password matches the hash!")
	} else {
		log.Printf("[DEBUG-PASSWORD]    ❌❌❌ FAILED! err = %v", err)
		log.Printf("[DEBUG-PASSWORD]")
		log.Printf("[DEBUG-PASSWORD] 6. Troubleshooting - Generate fresh hash for same password:")
		
		testHash, genErr := bcrypt.GenerateFromPassword(passwordBytes, bcrypt.DefaultCost)
		if genErr != nil {
			log.Printf("[DEBUG-PASSWORD]    ❌ Failed to generate test hash: %v", genErr)
		} else {
			freshHashStr := string(testHash)
			log.Printf("[DEBUG-PASSWORD]    Fresh hash generated: %s", freshHashStr)
			log.Printf("[DEBUG-PASSWORD]    Fresh hash length: %d", len(freshHashStr))
			log.Printf("[DEBUG-PASSWORD]")
			log.Printf("[DEBUG-PASSWORD]    Testing fresh hash with same password...")
			
			testErr := bcrypt.CompareHashAndPassword(testHash, passwordBytes)
			if testErr == nil {
				log.Printf("[DEBUG-PASSWORD]    ✅ Fresh hash WORKS!")
				log.Printf("[DEBUG-PASSWORD]")
				log.Printf("[DEBUG-PASSWORD]    📊 Comparison:")
				log.Printf("[DEBUG-PASSWORD]       Database hash: %s", hash)
				log.Printf("[DEBUG-PASSWORD]       Fresh hash:    %s", freshHashStr)
				log.Printf("[DEBUG-PASSWORD]")
				log.Printf("[DEBUG-PASSWORD]    🔍 Conclusion: Database hash is NOT for password '%s'", password)
			} else {
				log.Printf("[DEBUG-PASSWORD]    ❌ Fresh hash also FAILED: %v", testErr)
				log.Printf("[DEBUG-PASSWORD]    🔍 This suggests a bcrypt library or system issue")
			}
		}
		
		log.Printf("[DEBUG-PASSWORD]")
		log.Printf("[DEBUG-PASSWORD] 7. Additional diagnostics:")
		log.Printf("[DEBUG-PASSWORD]    bcrypt.Cost(hashBytes) check...")
		cost, costErr := bcrypt.Cost(hashBytes)
		if costErr != nil {
			log.Printf("[DEBUG-PASSWORD]    ❌ Failed to extract cost: %v", costErr)
			log.Printf("[DEBUG-PASSWORD]    This means the hash format is invalid!")
		} else {
			log.Printf("[DEBUG-PASSWORD]    ✅ Hash cost = %d", cost)
		}
	}
	
	log.Printf("[DEBUG-PASSWORD]")
	log.Printf("[DEBUG-PASSWORD] 8. Final result: %v", err == nil)
	log.Printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	
	return err == nil
}
