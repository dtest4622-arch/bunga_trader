//+------------------------------------------------------------------+
//| Bunga Trader MT5 Bridge EA                                       |
//+------------------------------------------------------------------+
#property copyright "Bunga Trader"
#property link      "https://bungatrader.com"
#property version   "1.00"
#property strict

#include <Zmq/Zmq.mqh>

// Input parameters
input string   Host = "*";
input int      Port = 5555;
input int      MagicNumber = 123456;
input int      PollTimeout = 1000;
input bool     EnableLogging = true;

// Global variables
Context context;
Socket socket(context, ZMQ_REP);
bool running = true;
ulong lastHeartbeat = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   EventSetTimer(1);
   
   // Initialize ZeroMQ socket
   if(!InitializeSocket())
   {
      Print("Failed to initialize ZeroMQ socket");
      return(INIT_FAILED);
   }
   
   Print("Bunga Trader EA started on port ", Port);
   Print("Magic Number: ", MagicNumber);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   running = false;
   
   // Close socket
   socket.unbind("tcp://" + Host + ":" + IntegerToString(Port));
   
   EventKillTimer();
   
   Print("Bunga Trader EA stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   ProcessZmqMessages();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   ProcessZmqMessages();
   
   // Send heartbeat every 30 seconds
   if(GetTickCount64() - lastHeartbeat > 30000)
   {
      lastHeartbeat = GetTickCount64();
   }
}

//+------------------------------------------------------------------+
//| Initialize ZeroMQ socket                                         |
//+------------------------------------------------------------------+
bool InitializeSocket()
{
   socket.setLinger(0);
   socket.setRcvTimeout(PollTimeout);
   
   string bindAddress = "tcp://" + Host + ":" + IntegerToString(Port);
   
   if(!socket.bind(bindAddress))
   {
      Print("Failed to bind to ", bindAddress);
      return false;
   }
   
   Print("ZeroMQ socket bound to ", bindAddress);
   return true;
}

//+------------------------------------------------------------------+
//| Process ZeroMQ messages                                          |
//+------------------------------------------------------------------+
void ProcessZmqMessages()
{
   ZmqMsg request;
   
   if(socket.recv(request, ZMQ_DONTWAIT))
   {
      string message = request.getData();
      
      if(EnableLogging)
         Print("Received: ", message);
      
      string response = ProcessCommand(message);
      
      ZmqMsg reply(response);
      socket.send(reply);
      
      if(EnableLogging)
         Print("Sent: ", response);
   }
}

//+------------------------------------------------------------------+
//| Process command                                                  |
//+------------------------------------------------------------------+
string ProcessCommand(string jsonCommand)
{
   JSONValue* root = JSONParse(jsonCommand);
   
   if(root == NULL)
      return "{\"error\":\"Invalid JSON\",\"success\":false}";
   
   string action = root["action"].ToStr();
   string result = "";
   
   if(action == "EXECUTE")
      result = ExecuteTrade(root);
   else if(action == "CLOSE")
      result = ClosePosition(root);
   else if(action == "MODIFY")
      result = ModifyPosition(root);
   else if(action == "ACCOUNT_INFO")
      result = GetAccountInfo();
   else if(action == "GET_POSITIONS")
      result = GetPositions();
   else if(action == "SYMBOL_INFO")
      result = GetSymbolInfo(root);
   else if(action == "MARKET_PRICE")
      result = GetMarketPrice(root);
   else if(action == "PING")
      result = "{\"success\":true,\"message\":\"pong\"}";
   else
      result = "{\"error\":\"Unknown action\",\"success\":false}";
   
   delete root;
   return result;
}

//+------------------------------------------------------------------+
//| Execute trade                                                    |
//+------------------------------------------------------------------+
string ExecuteTrade(JSONValue* params)
{
   string symbol = params["symbol"].ToStr();
   string typeStr = params["type"].ToStr();
   double volume = params["volume"].ToDbl();
   double sl = params["sl"].ToDbl();
   double tp = params["tp"].ToDbl();
   string comment = params["comment"].ToStr();
   
   ENUM_ORDER_TYPE orderType;
   double price;
   
   if(typeStr == "ORDER_TYPE_BUY")
   {
      orderType = ORDER_TYPE_BUY;
      price = SymbolInfoDouble(symbol, SYMBOL_ASK);
   }
   else
   {
      orderType = ORDER_TYPE_SELL;
      price = SymbolInfoDouble(symbol, SYMBOL_BID);
   }
   
   MqlTradeRequest request = {};
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = volume;
   request.type = orderType;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = MagicNumber;
   request.comment = comment;
   request.type_filling = GetFillingMode(symbol);
   
   MqlTradeResult tradeResult = {};
   
   if(!OrderSend(request, tradeResult))
   {
      int error = GetLastError();
      return StringFormat("{\"error\":\"%s\",\"error_code\":%d,\"success\":false}", 
                          GetErrorMessage(error), error);
   }
   
   return StringFormat("{\"success\":true,\"ticket\":%I64d,\"price\":%f,\"volume\":%f,\"comment\":\"%s\"}",
                       tradeResult.order, tradeResult.price, tradeResult.volume, comment);
}

//+------------------------------------------------------------------+
//| Close position                                                   |
//+------------------------------------------------------------------+
string ClosePosition(JSONValue* params)
{
   ulong ticket = (ulong)params["ticket"].ToInt();
   double partialPercent = params["partial_percent"].ToDbl();
   
   if(!PositionSelectByTicket(ticket))
      return "{\"error\":\"Position not found\",\"success\":false}";
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
   
   if(magic != MagicNumber)
      return "{\"error\":\"Position not managed by this EA\",\"success\":false}";
   
   double volume = PositionGetDouble(POSITION_VOLUME);
   if(partialPercent < 100)
      volume = NormalizeDouble(volume * partialPercent / 100, 2);
   
   ENUM_ORDER_TYPE closeType;
   double price;
   
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
   {
      closeType = ORDER_TYPE_SELL;
      price = SymbolInfoDouble(symbol, SYMBOL_BID);
   }
   else
   {
      closeType = ORDER_TYPE_BUY;
      price = SymbolInfoDouble(symbol, SYMBOL_ASK);
   }
   
   MqlTradeRequest request = {};
   request.action = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol = symbol;
   request.volume = volume;
   request.type = closeType;
   request.price = price;
   request.deviation = 10;
   request.magic = MagicNumber;
   request.type_filling = GetFillingMode(symbol);
   
   MqlTradeResult result = {};
   if(!OrderSend(request, result))
   {
      int error = GetLastError();
      return StringFormat("{\"error\":\"%s\",\"error_code\":%d,\"success\":false}",
                          GetErrorMessage(error), error);
   }
   
   return StringFormat("{\"success\":true,\"ticket\":%I64d,\"price\":%f,\"profit\":%f,\"volume\":%f}",
                       result.order, result.price, result.profit, result.volume);
}

//+------------------------------------------------------------------+
//| Modify position                                                  |
//+------------------------------------------------------------------+
string ModifyPosition(JSONValue* params)
{
   ulong ticket = (ulong)params["ticket"].ToInt();
   double newSl = params["sl"].ToDbl();
   double newTp = params["tp"].ToDbl();
   
   if(!PositionSelectByTicket(ticket))
      return "{\"error\":\"Position not found\",\"success\":false}";
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   
   MqlTradeRequest request = {};
   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.symbol = symbol;
   request.sl = newSl;
   request.tp = newTp;
   
   MqlTradeResult result = {};
   if(!OrderSend(request, result))
   {
      int error = GetLastError();
      return StringFormat("{\"error\":\"%s\",\"error_code\":%d,\"success\":false}",
                          GetErrorMessage(error), error);
   }
   
   return "{\"success\":true}";
}

//+------------------------------------------------------------------+
//| Get account info                                                 |
//+------------------------------------------------------------------+
string GetAccountInfo()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double margin = AccountInfoDouble(ACCOUNT_MARGIN);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   string currency = AccountInfoString(ACCOUNT_CURRENCY);
   int leverage = (int)AccountInfoInteger(ACCOUNT_LEVERAGE);
   
   return StringFormat(
      "{\"balance\":%f,\"equity\":%f,\"margin\":%f,\"free_margin\":%f,\"margin_level\":%f,\"currency\":\"%s\",\"leverage\":%d,\"success\":true}",
      balance, equity, margin, freeMargin, marginLevel, currency, leverage
   );
}

//+------------------------------------------------------------------+
//| Get positions                                                    |
//+------------------------------------------------------------------+
string GetPositions()
{
   string positions = "[";
   int total = PositionsTotal();
   
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      
      if(i > 0) positions += ",";
      
      positions += StringFormat(
         "{\"ticket\":%I64d,\"symbol\":\"%s\",\"type\":\"%s\",\"volume\":%f,\"open_price\":%f,\"sl\":%f,\"tp\":%f,\"profit\":%f,\"swap\":%f}",
         ticket,
         PositionGetString(POSITION_SYMBOL),
         PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY" : "SELL",
         PositionGetDouble(POSITION_VOLUME),
         PositionGetDouble(POSITION_PRICE_OPEN),
         PositionGetDouble(POSITION_SL),
         PositionGetDouble(POSITION_TP),
         PositionGetDouble(POSITION_PROFIT),
         PositionGetDouble(POSITION_SWAP)
      );
   }
   
   positions += "]";
   return StringFormat("{\"positions\":%s,\"count\":%d,\"success\":true}", positions, total);
}

//+------------------------------------------------------------------+
//| Get symbol info                                                  |
//+------------------------------------------------------------------+
string GetSymbolInfo(JSONValue* params)
{
   string symbol = params["symbol"].ToStr();
   
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   return StringFormat(
      "{\"symbol\":\"%s\",\"point\":%f,\"digits\":%d,\"spread\":%f,\"min_lot\":%f,\"max_lot\":%f,\"lot_step\":%f,\"success\":true}",
      symbol, point, digits, spread, minLot, maxLot, lotStep
   );
}

//+------------------------------------------------------------------+
//| Get market price                                                 |
//+------------------------------------------------------------------+
string GetMarketPrice(JSONValue* params)
{
   string symbol = params["symbol"].ToStr();
   
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   
   return StringFormat(
      "{\"symbol\":\"%s\",\"bid\":%f,\"ask\":%f,\"success\":true}",
      symbol, bid, ask
   );
}

//+------------------------------------------------------------------+
//| Get filling mode                                                 |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFillingMode(string symbol)
{
   uint filling = (uint)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
   
   if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   
   if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;
   
   return ORDER_FILLING_RETURN;
}

//+------------------------------------------------------------------+
//| Get error message                                                |
//+------------------------------------------------------------------+
string GetErrorMessage(int errorCode)
{
   switch(errorCode)
   {
      case TRADE_RETCODE_REQUOTE: return "Requote";
      case TRADE_RETCODE_REJECT: return "Request rejected";
      case TRADE_RETCODE_CANCEL: return "Request canceled";
      case TRADE_RETCODE_PLACED: return "Order placed";
      case TRADE_RETCODE_DONE: return "Request completed";
      case TRADE_RETCODE_DONE_PARTIAL: return "Request completed partially";
      case TRADE_RETCODE_ERROR: return "Processing error";
      case TRADE_RETCODE_TIMEOUT: return "Request timeout";
      case TRADE_RETCODE_INVALID: return "Invalid request";
      case TRADE_RETCODE_INVALID_VOLUME: return "Invalid volume";
      case TRADE_RETCODE_INVALID_PRICE: return "Invalid price";
      case TRADE_RETCODE_INVALID_STOPS: return "Invalid stops";
      case TRADE_RETCODE_TRADE_DISABLED: return "Trade disabled";
      case TRADE_RETCODE_MARKET_CLOSED: return "Market closed";
      case TRADE_RETCODE_NO_MONEY: return "Not enough money";
      case TRADE_RETCODE_PRICE_OFF: return "Price off";
      case TRADE_RETCODE_INVALID_EXPIRATION: return "Invalid expiration";
      case TRADE_RETCODE_ORDER_CHANGED: return "Order changed";
      case TRADE_RETCODE_TOO_MANY_REQUESTS: return "Too many requests";
      case TRADE_RETCODE_NO_CHANGES: return "No changes";
      case TRADE_RETCODE_SERVER_DISABLES_AT: return "Server disables AT";
      case TRADE_RETCODE_CLIENT_DISABLES_AT: return "Client disables AT";
      case TRADE_RETCODE_LOCKED: return "Request locked";
      case TRADE_RETCODE_FROZEN: return "Order or position frozen";
      case TRADE_RETCODE_INVALID_FILL: return "Invalid fill type";
      case TRADE_RETCODE_CONNECTION: return "No connection";
      case TRADE_RETCODE_ONLY_REAL: return "Allowed for real accounts only";
      case TRADE_RETCODE_LIMIT_ORDERS: return "Limit of pending orders reached";
      case TRADE_RETCODE_LIMIT_VOLUME: return "Limit of volume reached";
      default: return "Unknown error";
   }
}
//+------------------------------------------------------------------+
