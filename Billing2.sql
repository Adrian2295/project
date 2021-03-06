USE [BlueMobile]
GO
/****** Object:  StoredProcedure [dbo].[InsertBilling]    Script Date: 7/27/2020 4:25:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[InsertBilling]
AS
SET NOCOUNT ON
asdasd
		BEGIN TRY
			BEGIN TRANSACTION
				
				DECLARE @Today date = dateadd(month,1,getdate())

				INSERT INTO dbo.Billing (UserID, SubscriptionID, DueDate, BillStatusID,CallCost)
				SELECT a.UserID, a.SubscriptionsId, DATEADD(DAY,+7,@Today),1,SUM(c.Cost)
				FROM dbo.Subscriptions a
				INNER JOIN dbo.SimCards b ON a.SimCardID = b.SimCardsId
				INNER JOIN dbo.Calls c ON b.PhoneNumber = c.CallerSim AND c.StartTime >= a.StartDate AND c.EndTime <= a.EndDate
				WHERE EndDate = @Today  AND a.SubsStatusID = 1
				GROUP BY CallerSim,a.UserID,SubscriptionsId

				SELECT c.FromPerson1,b.UserID, a.SubscriptionsId, SUM(c.Cost) AS TotalCostSms
				INTO #SmsCostTempTable
				FROM dbo.Subscriptions a
				INNER JOIN dbo.SimCards b ON a.SimCardID = b.SimCardsId
				INNER JOIN dbo.Sms c ON b.PhoneNumber = c.FromPerson1 AND c.[DateTime] >= a.StartDate AND c.[DateTime] <= a.EndDate
				WHERE a.SubsStatusID = 1 and EndDate = @Today
				GROUP BY c.FromPerson1, b.UserID, a.SubscriptionsId
				
				UPDATE dbo.Billing
				SET SmsCost = TotalCostSms
				FROM #SmsCostTempTable a
				INNER JOIN dbo.SimCards b ON a.FromPerson1 = b.PhoneNumber
				INNER JOIN dbo.Billing c ON a.UserID = b.UserID
				
				INSERT INTO dbo.Billing
				SELECT a.UserID, b.SubscriptionID, DATEADD(DAY,+7,@Today), 1, 0, TotalCostSms
				FROM #SmsCostTempTable a
				LEFT JOIN dbo.Billing b ON a.SubscriptionsId = b.SubscriptionID
				WHERE b.SubscriptionID IS NULL
				
				drop table #SmsCostTempTable

			COMMIT TRANSACTION
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
					ROLLBACK TRANSACTION
			DECLARE @ErrorMessage nvarchar(4000)
			DECLARE @ErrorSeverity int
			DECLARE @ErrorState int
			SELECT @ErrorMessage = ERROR_MESSAGE(),
				   @ErrorSeverity = ERROR_SEVERITY(),
				   @ErrorState = ERROR_STATE()

			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)

		END CATCH
