import {Common, Qot_Common, Trd_Common} from 'futu-api/proto'
{QotMarket, KLType, SubType} = Qot_Common
{OrderType, SecurityFirm, TrdEnv, TrdMarket, TrdSecMarket, TrdSide} = Trd_Common

export default
  klType:
    '1': KLType.KLType_1Min
    '5': KLType.KLType_5Min
    '15': KLType.KLType_15Min
    '30': KLType.KLType_30Min
    '1h': KLType.KLType_60Min
    '1d': KLType.KLType_Day
    '1w': KLType.KLType_Week
    '1m': KLType.KLType_Month
    '1y': KLType.KLType_Year
  market:
    unknown: 0
    hkSecurity: 1
    hkFuture: 2
    usSecurity: 11
    cnshSecurity: 21
    cnszSecurity: 22
    sgSecurity: 31
    jpSecurity: 41
  SubType: SubType
  QotMarket: QotMarket
  OrderType: OrderType
  SecurityFirm: SecurityFirm
  TrdEnv: TrdEnv
  TrdMarket: TrdMarket
  TrdSecMarket: TrdSecMarket
  TrdSide: TrdSide
