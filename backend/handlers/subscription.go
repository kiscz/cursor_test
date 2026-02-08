package handlers

import (
	"net/http"
	"os"
	"shortdrama/database"
	"shortdrama/models"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/checkout/session"
	"github.com/stripe/stripe-go/v76/webhook"
)

func init() {
	stripe.Key = os.Getenv("STRIPE_SECRET_KEY")
	if stripe.Key == "" {
		stripe.Key = "sk_test_your_key" // fallback for development
	}
}

func CreateCheckoutSession(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		Plan string `json:"plan" binding:"required"` // monthly or yearly
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get user
	var user models.User
	if err := database.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Check if Stripe is properly configured
	stripeKey := os.Getenv("STRIPE_SECRET_KEY")
	if stripeKey == "" || stripeKey == "sk_test_your_key" {
		// Development mode: simulate subscription without Stripe
		// Create a mock subscription directly
		now := time.Now()
		var periodEnd time.Time
		if req.Plan == "yearly" {
			periodEnd = now.AddDate(1, 0, 0)
		} else {
			periodEnd = now.AddDate(0, 1, 0)
		}

		// Check if user already has an active subscription
		var existingSub models.Subscription
		if err := database.DB.Where("user_id = ? AND status = ?", userID, "active").
			First(&existingSub).Error; err == nil {
			// Update existing subscription
			database.DB.Model(&existingSub).Updates(map[string]interface{}{
				"plan_name":          req.Plan,
				"current_period_start": now,
				"current_period_end": periodEnd,
				"status":             "active",
			})
		} else {
			// Create new subscription
			var amount float64
			if req.Plan == "yearly" {
				amount = 79.99
			} else {
				amount = 9.99
			}
			
			subscription := models.Subscription{
				UserID:               userID,
				StripeSubscriptionID: "dev_sub_" + strconv.Itoa(int(userID)) + "_" + strconv.FormatInt(time.Now().Unix(), 10),
				PlanName:             req.Plan,
				Amount:               amount,
				Currency:             "USD",
				Status:               "active",
				CurrentPeriodStart:   now,
				CurrentPeriodEnd:     periodEnd,
			}
			database.DB.Create(&subscription)
		}

		// Update user premium status
		database.DB.Model(&user).Updates(map[string]interface{}{
			"is_premium":        true,
			"premium_expires_at": &periodEnd,
		})

		// Return success response with mock checkout URL
		c.JSON(http.StatusOK, gin.H{
			"url": "/membership/success?session_id=dev_session_" + strconv.FormatInt(time.Now().Unix(), 10),
			"message": "Subscription activated (development mode)",
		})
		return
	}

	// Production mode: Use real Stripe
	// Determine price ID
	priceID := os.Getenv("STRIPE_PRICE_MONTHLY")
	if req.Plan == "yearly" {
		priceID = os.Getenv("STRIPE_PRICE_YEARLY")
	}

	if priceID == "" {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Stripe price IDs not configured. Please set STRIPE_PRICE_MONTHLY and STRIPE_PRICE_YEARLY environment variables.",
		})
		return
	}

	// Create checkout session
	params := &stripe.CheckoutSessionParams{
		CustomerEmail: stripe.String(user.Email),
		Mode:          stripe.String(string(stripe.CheckoutSessionModeSubscription)),
		LineItems: []*stripe.CheckoutSessionLineItemParams{
			{
				Price:    stripe.String(priceID),
				Quantity: stripe.Int64(1),
			},
		},
		SuccessURL: stripe.String(os.Getenv("APP_URL") + "/membership/success?session_id={CHECKOUT_SESSION_ID}"),
		CancelURL:  stripe.String(os.Getenv("APP_URL") + "/membership"),
		Metadata: map[string]string{
			"user_id": strconv.Itoa(int(userID)),
			"plan":    req.Plan,
		},
	}

	sess, err := session.New(params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to create checkout session: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"url": sess.URL,
	})
}

func HandleStripeWebhook(c *gin.Context) {
	payload, err := c.GetRawData()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid payload"})
		return
	}

	webhookSecret := os.Getenv("STRIPE_WEBHOOK_SECRET")
	event, err := webhook.ConstructEvent(payload, c.GetHeader("Stripe-Signature"), webhookSecret)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid signature"})
		return
	}

	switch event.Type {
	case "checkout.session.completed":
		handleCheckoutCompleted(event.Data.Raw)
	case "customer.subscription.updated":
		handleSubscriptionUpdated(event.Data.Raw)
	case "customer.subscription.deleted":
		handleSubscriptionDeleted(event.Data.Raw)
	}

	c.JSON(http.StatusOK, gin.H{"received": true})
}

func handleCheckoutCompleted(data []byte) {
	// Parse checkout session and create subscription record
	// Implementation depends on your Stripe setup
}

func handleSubscriptionUpdated(data []byte) {
	// Update subscription status
}

func handleSubscriptionDeleted(data []byte) {
	// Mark subscription as cancelled
}

func GetSubscriptionStatus(c *gin.Context) {
	userID := c.GetUint("userID")

	var subscription models.Subscription
	if err := database.DB.Where("user_id = ? AND status = ?", userID, "active").
		Order("created_at DESC").
		First(&subscription).Error; err != nil {
		c.JSON(http.StatusOK, gin.H{
			"is_active": false,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"is_active":           true,
		"plan":                subscription.PlanName,
		"current_period_end":  subscription.CurrentPeriodEnd,
	})
}

func CancelSubscription(c *gin.Context) {
	userID := c.GetUint("userID")

	var subscription models.Subscription
	if err := database.DB.Where("user_id = ? AND status = ?", userID, "active").
		First(&subscription).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active subscription found"})
		return
	}

	// Cancel on Stripe (implementation needed)
	// For now, just mark as cancelled in DB
	now := time.Now()
	database.DB.Model(&subscription).Updates(map[string]interface{}{
		"status":       "cancelled",
		"cancelled_at": &now,
	})

	// Update user premium status
	var user models.User
	if err := database.DB.First(&user, userID).Error; err == nil {
		database.DB.Model(&user).Updates(map[string]interface{}{
			"is_premium":        false,
			"premium_expires_at": nil,
		})
	}

	c.JSON(http.StatusOK, gin.H{"message": "Subscription cancelled"})
}
