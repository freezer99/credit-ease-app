import { format } from "date-fns";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { DollarSign, Calendar, TrendingDown, TrendingUp } from "lucide-react";

interface Payment {
  id: number;
  amount: number;
  date: string;
}

interface Borrower {
  id: number;
  name: string;
  originalAmount: number;
  amount: number;
  created: string;
  payments: Payment[];
}

interface BorrowerCardProps {
  borrower: Borrower;
  onRecordPayment: (id: number) => void;
}

const BorrowerCard = ({ borrower, onRecordPayment }: BorrowerCardProps) => {
  const totalPaid = borrower.payments.reduce((sum, payment) => sum + payment.amount, 0);
  const isFullyPaid = borrower.amount <= 0;
  
  return (
    <Card className="bg-gradient-card border-border/50 shadow-card hover:shadow-elegant transition-all duration-300">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg font-semibold text-foreground">
            {borrower.name}
          </CardTitle>
          <Badge 
            variant={isFullyPaid ? "default" : "secondary"}
            className={isFullyPaid ? "bg-success text-success-foreground" : ""}
          >
            {isFullyPaid ? "Paid Off" : "Active"}
          </Badge>
        </div>
      </CardHeader>
      
      <CardContent className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <div className="flex items-center text-sm text-muted-foreground">
              <DollarSign className="w-4 h-4 mr-1" />
              Current Balance
            </div>
            <div className="text-2xl font-bold text-primary">
              ${borrower.amount.toFixed(2)}
            </div>
          </div>
          
          <div className="space-y-1">
            <div className="flex items-center text-sm text-muted-foreground">
              <TrendingUp className="w-4 h-4 mr-1" />
              Original Loan
            </div>
            <div className="text-lg font-semibold text-foreground">
              ${borrower.originalAmount.toFixed(2)}
            </div>
          </div>
        </div>
        
        {totalPaid > 0 && (
          <div className="space-y-1">
            <div className="flex items-center text-sm text-muted-foreground">
              <TrendingDown className="w-4 h-4 mr-1" />
              Total Paid
            </div>
            <div className="text-lg font-semibold text-success">
              ${totalPaid.toFixed(2)}
            </div>
          </div>
        )}
        
        <div className="flex items-center text-sm text-muted-foreground">
          <Calendar className="w-4 h-4 mr-1" />
          Created {format(new Date(borrower.created), 'MMM d, yyyy')}
        </div>
        
        {borrower.payments.length > 0 && (
          <div className="pt-2 border-t border-border/50">
            <div className="text-sm text-muted-foreground mb-2">Recent Payments:</div>
            <div className="space-y-1 max-h-20 overflow-y-auto">
              {borrower.payments.slice(0, 3).map((payment) => (
                <div key={payment.id} className="flex justify-between text-sm">
                  <span className="text-muted-foreground">
                    {format(new Date(payment.date), 'MMM d')}
                  </span>
                  <span className="text-success font-medium">
                    ${payment.amount.toFixed(2)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}
        
        <Button 
          onClick={() => onRecordPayment(borrower.id)}
          disabled={isFullyPaid}
          className="w-full bg-primary hover:bg-primary/90 text-primary-foreground"
        >
          {isFullyPaid ? "Loan Paid Off" : "Record Payment"}
        </Button>
      </CardContent>
    </Card>
  );
};

export default BorrowerCard;