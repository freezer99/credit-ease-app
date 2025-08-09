import { useState, useEffect } from "react";
import { format } from "date-fns";
import AddLoanForm from "@/components/AddLoanForm";
import BorrowerCard from "@/components/BorrowerCard";
import { Card, CardContent } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { TrendingUp, TrendingDown, Users, DollarSign, Briefcase } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

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

const Index = () => {
  const [borrowers, setBorrowers] = useState<Borrower[]>([]);
  const { toast } = useToast();

  useEffect(() => {
    const data = JSON.parse(localStorage.getItem('loanshrk:data') || '[]');
    setBorrowers(data);
  }, []);

  useEffect(() => {
    localStorage.setItem('loanshrk:data', JSON.stringify(borrowers));
  }, [borrowers]);

  const addLoan = (name: string, amount: number) => {
    const newBorrower: Borrower = {
      id: Date.now(),
      name,
      originalAmount: amount,
      amount,
      created: new Date().toISOString(),
      payments: []
    };
    
    setBorrowers([newBorrower, ...borrowers]);
    
    toast({
      title: "Loan Added",
      description: `$${amount.toFixed(2)} loan created for ${name}`,
    });
  };

  const recordPayment = (id: number) => {
    const paymentAmount = window.prompt('Enter payment amount:');
    if (!paymentAmount || isNaN(parseFloat(paymentAmount))) return;

    const amount = parseFloat(paymentAmount);
    if (amount <= 0) return;

    setBorrowers(borrowers.map(borrower => {
      if (borrower.id === id) {
        const newPayment: Payment = {
          id: Date.now(),
          amount,
          date: new Date().toISOString()
        };
        
        const newAmount = Math.max(0, borrower.amount - amount);
        
        toast({
          title: "Payment Recorded",
          description: `$${amount.toFixed(2)} payment recorded for ${borrower.name}`,
        });
        
        return {
          ...borrower,
          payments: [...borrower.payments, newPayment],
          amount: newAmount
        };
      }
      return borrower;
    }));
  };

  // Calculate statistics
  const totalLoansOut = borrowers.reduce((sum, b) => sum + b.amount, 0);
  const totalOriginalAmount = borrowers.reduce((sum, b) => sum + b.originalAmount, 0);
  const totalCollected = totalOriginalAmount - totalLoansOut;
  const activeBorrowers = borrowers.filter(b => b.amount > 0).length;

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <header className="mb-8">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-primary rounded-lg flex items-center justify-center shadow-elegant">
                <Briefcase className="w-6 h-6 text-primary-foreground" />
              </div>
              <div>
                <h1 className="text-3xl font-bold text-foreground">LoanShrk</h1>
                <p className="text-muted-foreground">Loan Management Dashboard</p>
              </div>
            </div>
            <div className="text-right">
              <div className="text-sm text-muted-foreground">Today</div>
              <div className="text-lg font-semibold text-foreground">
                {format(new Date(), 'PPP')}
              </div>
            </div>
          </div>
        </header>

        {/* Statistics Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <Card className="bg-gradient-card border-border/50 shadow-card">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground">Outstanding</p>
                  <p className="text-2xl font-bold text-primary">${totalLoansOut.toFixed(2)}</p>
                </div>
                <TrendingUp className="w-8 h-8 text-primary" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-card border-border/50 shadow-card">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground">Collected</p>
                  <p className="text-2xl font-bold text-success">${totalCollected.toFixed(2)}</p>
                </div>
                <TrendingDown className="w-8 h-8 text-success" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-card border-border/50 shadow-card">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground">Total Loaned</p>
                  <p className="text-2xl font-bold text-foreground">${totalOriginalAmount.toFixed(2)}</p>
                </div>
                <DollarSign className="w-8 h-8 text-foreground" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-card border-border/50 shadow-card">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground">Active Loans</p>
                  <p className="text-2xl font-bold text-foreground">{activeBorrowers}</p>
                </div>
                <Users className="w-8 h-8 text-foreground" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Add Loan Form */}
        <div className="mb-8">
          <AddLoanForm onAddLoan={addLoan} />
        </div>

        <Separator className="mb-8" />

        {/* Borrowers List */}
        <section>
          <h2 className="text-2xl font-semibold text-foreground mb-6">
            {borrowers.length === 0 ? "No Loans Yet" : `Loans (${borrowers.length})`}
          </h2>

          {borrowers.length === 0 ? (
            <Card className="bg-gradient-card border-border/50 shadow-card">
              <CardContent className="p-12 text-center">
                <div className="w-16 h-16 bg-muted rounded-full flex items-center justify-center mx-auto mb-4">
                  <Briefcase className="w-8 h-8 text-muted-foreground" />
                </div>
                <p className="text-lg text-muted-foreground">
                  Add your first loan using the form above to get started.
                </p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {borrowers.map((borrower) => (
                <BorrowerCard
                  key={borrower.id}
                  borrower={borrower}
                  onRecordPayment={recordPayment}
                />
              ))}
            </div>
          )}
        </section>
      </div>
    </div>
  );
};

export default Index;