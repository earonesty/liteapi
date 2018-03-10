This API is designed to be compatible with the BitCoin Receive Payments API, so sites that accept BitCoin can easily add StrayaCoin support. You will need a StrayaCoin address to use this API. This is the address where transactions will be forwarded to.

Request an Address

The minimum supported transaction size is 0.01 NAH.

For example:

https://nahapi.org/receive?method=create&address=$receiving_address&callback=$callback_url

See https://nahapi.org for more information.
