# ITTs-DonationBot ( ITTDB )

This addon was developed by @Ghostbane!
I (JN Slevin) have recently gotten permission from him to maintain the addon.
I am hoping to maintain it and add features and requests (to the best of my ability)


#### Languages: EN, RU, DE, FR

Donation Bot is a simple and unintrusive addon that helps Trade GMs and Staff track guild deposits from its members. Adding a column beside member notes, you will be able to see various totals based on the time filter dropdown at the bottom of the screen.

Hovering over a members donation field will give you a tooltip of information relative to that user. On the left hand side is a log of the last 5 donations, on the right is various totals based on time.

### Features
- Log + Summary Tooltip ( Only displays if there is data for the person )
- Donations column, sortable, in the Guild Roster
- Time dropdown for query selection
- On-screen notifications
- Chat notifications
- Lotto / Raffle Generator

### Commands
#### Re-generate the tooltip cache
`/itt-donation-cache <i>`
  - ie. /itt-donation-cache 2
    - Note: The number 2, being the second guild in the users guild list.
    For performance, tooltips are generated individually as Donation Bot receives the data. This happens so it isn't constructed every time you hover over a guild member's row in the roster. Sometimes with a large influx of information, some member's tooltips may not get updated, or if in-general game performance is staggering. You can manually re-generate a guilds tooltips with this command.
    
### Compatibility 

Whilst these are not dependencies to make this addon work, I know that GMs + Staff will likely have these tools turned on, presented inside their roster.

We have developed Donation Bot alongside,
#### Supported:
1. Arkadius' Trade Tools
2. Master Merchant 3.0
#### Not Supported:
1. Master Merchant 2.x
2. Shissu's Roster
  - Note: Enabling any of the "additional columns" in the Shissu settings, triggers an anchor cycle warning, which could potentially crash your game. Disable these columns in the Shissu Roster settings.


## EU Beta test team
- @Fiktius - GM of Rolling Coins, Shining Coins, Flipping Coins
- @JN_Slevin - GM of -Cashflow, Tamriels Emporium, Merchants of Magnus, The Noble Merchants and Eternal Forest Merchantry
- @HSVFAN - GM of -Cashflow, Tamriels Emporium, Merchants of Magnus, The Noble Merchants and Eternal Forest Merchantry
- @Lissy3001 - GM of Rächer-Handelskontor
- @countdownical - Co-GM of Rolling Coins, Shining Coins, Flipping Coins
- @SammiSakura - GM of The Forbidden Cleavage, Brave Cat Trade, The Forbidden Union and Daedric Baanditos
- @JKaba40k - GM of Capital of Avalon

## Translation team
- RU - @JKaba40k
- DE - @JN_Slevin + @Lissy3001
- EN - The British invasion of Ireland cite 1169
- FR - @Barzoth

## More to come 
Too long Trade GMs and Staff have had outdated tools or inconsistent experiences to do the daily maintenance required of running a functioning Trade Guild. Donation Bot is the first addition of many, in terms of helpful and modern tools to get the job done.

## About ITT 
Independent Trading Team is a trade alliance on PC-EU, always looking to provide a productive community for its traders and partners.
