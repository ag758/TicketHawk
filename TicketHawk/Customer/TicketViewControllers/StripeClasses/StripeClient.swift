import Foundation
import Alamofire
import Stripe

enum Result {
  case success
  case failure(Error)
}

final class StripeClient {
  
  static let shared = StripeClient()
  
  private init() {
    // private
  }
  
  private lazy var baseURL: URL = {
    guard let url = URL(string: Constants.baseURLString) else {
      fatalError("Invalid URL")
    }
    return url
  }()
    
    func completeCharge(with token: STPToken, amount: Int, accountID: String, feeAmount: Int, completion: @escaping (Result) -> Void) {
        // 1
        let url = baseURL.appendingPathComponent("charge")
        // 2
        let params: [String: Any] = [
            "token": token.tokenId,
            "amount": amount,
            "currency": Constants.defaultCurrency,
            "description": Constants.defaultDescription,
            "application_fee_amount": feeAmount,
            "account_id": accountID
        ]
        
        print(accountID)
        print(feeAmount)
        // 3
        Alamofire.request(url, method: .post, parameters: params)
            .validate(statusCode: 200..<300)
            .responseString { response in
                switch response.result {
                case .success:
                    completion(Result.success)
                case .failure(let error):
                    completion(Result.failure(error))
                }
        }
    }
  
}
