require 'rspec'
require 'timecop'
require 'time_only'

describe TimeOnly do
  describe '.new(args)' do
    context 'one arg' do
      it 'creates as the seconds since midnight' do
        expect(described_class.new(45296).to_i).to eq(45296)
      end

      it "rolls over seconds that are greater than #{described_class::SECONDS_PER_DAY}" do
        expect(described_class.new(described_class::SECONDS_PER_DAY * 2 + 1).to_i).to eq(1)
      end

      it 'handles negative seconds which rolls back' do
        expect(described_class.new(-10).to_i).to eq(described_class::SECONDS_PER_DAY - 10)
      end
    end

    context 'three argss' do
      it 'creates based on hours, minutes and seconds' do
        expect(described_class.new(12, 34, 56).to_i).to eq(45296)
      end

      it 'raises an error when the hours arg is outside of 0 - 23' do
        expect{ described_class.new(24, 0, 0) }.to raise_error(ArgumentError)
      end

      it 'raises an error when the minutes arg is outside of 0 - 59' do
        expect{ described_class.new(0, 60, 0) }.to raise_error(ArgumentError)
      end

      it 'raises an error when the seconds arg is outside of 0 - 59' do
        expect{ described_class.new(0, 0, 60) }.to raise_error(ArgumentError)
      end
    end

    it 'raises an error when the wrong number of arguments is passed' do
      expect{ described_class.new(1, 2) }.to raise_error(ArgumentError)
    end
  end

  describe '.at(seconds)' do
    it 'creates a time based on the number of seconds since midnight' do
      expect(described_class.at(300).to_i).to eq(300)
    end

    it "rolls over seconds that are greater than #{described_class::SECONDS_PER_DAY}" do
      expect(described_class.at(described_class::SECONDS_PER_DAY * 2 + 1).to_i).to eq(1)
    end

    it 'handles negative seconds which rolls back' do
      expect(described_class.at(-10).to_i).to eq(described_class::SECONDS_PER_DAY - 10)
    end
  end

  describe '.now' do
    it "returns a #{described_class} object for the current system time" do
      hour, min, sec = 12, 34, 56

      Timecop.freeze(Time.local(2012, 11, 30, hour, min, sec)) do
        expect(described_class.now.to_s).to eq("#{hour}:#{min}:#{sec}")
      end
    end
  end

  describe '#+(seconds)' do
    it "returns a new #{described_class} object with n seconds added to it" do
      current_time = described_class.new(0)
      new_time = current_time + 1

      expect(current_time).not_to equal(new_time)
      expect(new_time).to eq(described_class.new(1))
    end

    it 'rolls over time when greater than 23:59:59' do
      expect(described_class.new(23, 59, 59) + 2).to eq(described_class.new(0, 0, 1))
    end
  end

  describe '#-(seconds)' do
    it "returns a new #{described_class} object with n seconds subtracted from it" do
      current_time = described_class.new(1)
      new_time = current_time - 1

      expect(current_time).not_to equal(new_time)
      expect(new_time).to eq(described_class.new(0))
    end

    it 'rolls back time when less than 00:00:00' do
      expect(described_class.new(00, 00, 01) - 2).to eq(described_class.new(23, 59, 59))
    end
  end

  describe '#==(other)' do # aliases: eql?
    it 'returns true when the times are the same' do
      expect(described_class.new(12, 34, 56) == described_class.new(12, 34, 56)).to be_true
    end

    it 'returns false when the times are not the same' do
      expect(described_class.new(12, 34, 56) == described_class.new(0, 0, 0)).to be_false
    end
  end

  describe '#<=>(other)' do
    it 'returns 0 when the times are equal' do
      other = described_class.new(0)

      expect(described_class.new(0) <=> other).to eq(0)
    end

    it 'returns -1 when the times are equal' do
      other = described_class.new(1)

      expect(described_class.new(0) <=> other).to eq(-1)
    end
    
    it 'returns 1 when the times are equal' do
      other = described_class.new(0)

      expect(described_class.new(1) <=> other).to eq(1)
    end
  end

  describe '#am?' do
    context 'time is before noon' do
      subject { described_class.new(2, 4, 6) }

      its(:am?) { should be_true }
    end

    context 'time is after noon' do
      subject { described_class.new(12, 4, 6) }

      its(:am?) { should be_false }
    end
  end

  describe '#hour' do
    subject { described_class.new(2, 4, 6) }

    its(:hour) { should be 2 }
  end

  describe '#min' do
    subject { described_class.new(2, 4, 6) }

    its(:min) { should be 4 }
  end

  describe '#pm?' do
    context 'time is before noon' do
      subject { described_class.new(2, 4, 6) }

      its(:pm?) { should be_false }
    end

    context 'time is after noon' do
      subject { described_class.new(12, 4, 6) }

      its(:pm?) { should be_true }
    end
  end

  describe '#sec' do
    subject { described_class.new(2, 4, 6) }

    its(:sec) { should be 6 }
  end

  describe '#strftime' do
    context 'flags' do
      context "- don't pad a numerical output" do
        context 'hour' do
          %w(H k I l).each do |directive|
            context "using %#{directive}" do
              it 'hour is one digit' do
                expect(described_class.new(8, 0, 0).strftime("%-#{directive}")).to eq('8')
              end

              it 'hour is two digits' do
                if directive == 'I' || directive == 'l'
                  hour, hour_s = 13, '1'
                else
                  hour, hour_s = 12, '12'
                end

                expect(described_class.new(hour, 0, 0).strftime("%-#{directive}")).to eq(hour_s)
              end
            end
          end
        end

        context 'min' do
          it 'min is one digit' do
            expect(described_class.new(0, 8, 0).strftime('%-M')).to eq('8')
          end

          it 'min is two digits' do
            expect(described_class.new(0, 12, 0).strftime('%-M')).to eq('12')
          end
        end

        context 'sec' do
          it 'sec is one digit' do
            expect(described_class.new(0, 0, 8).strftime('%-S')).to eq('8')
          end

          it 'sec is two digits' do
            expect(described_class.new(0, 0, 12).strftime('%-S')).to eq('12')
          end
        end
      end
    end

    context 'directives' do
      context '%H - Hour of the day, 24-hour clock, zero-padded (00..23)' do
        it 'hour is one digit' do
          expect(described_class.new(8, 0, 0).strftime('%H')).to eq('08')
        end

        it 'hour is two digits' do
          expect(described_class.new(12, 0, 0).strftime('%H')).to eq('12')
        end
      end

      context '%k - Hour of the day, 24-hour clock, blank-padded ( 0..23)' do
        it 'hour is one digit' do
          expect(described_class.new(8, 0, 0).strftime('%k')).to eq(' 8')
        end

        it 'hour is two digits' do
          expect(described_class.new(12, 0, 0).strftime('%k')).to eq('12')
        end
      end

      context '%I - Hour of the day, 12-hour clock, zero-padded (01..12)' do
        context 'before 1pm' do
          it 'hour is one digit' do
            expect(described_class.new(8, 0, 0).strftime('%I')).to eq('08')
          end

          it 'hour is two digits' do
            expect(described_class.new(12, 0, 0).strftime('%I')).to eq('12')
          end
        end

        context 'after or equal to 1pm' do
          it 'hour is one digit' do
            expect(described_class.new(13, 0, 0).strftime('%I')).to eq('01')
          end

          it 'hour is two digits' do
            expect(described_class.new(22, 0, 0).strftime('%I')).to eq('10')
          end
        end
      end

      context '%l - Hour of the day, 12-hour clock, blank-padded ( 1..12)' do
        context 'before 1pm' do
          it 'hour is one digit' do
            expect(described_class.new(8, 0, 0).strftime('%l')).to eq(' 8')
          end

          it 'hour is two digits' do
            expect(described_class.new(12, 0, 0).strftime('%l')).to eq('12')
          end
        end

        context 'after or equal to 1pm' do
          it 'hour is one digit' do
            expect(described_class.new(13, 0, 0).strftime('%l')).to eq(' 1')
          end

          it 'hour is two digits' do
            expect(described_class.new(22, 0, 0).strftime('%l')).to eq('10')
          end
        end
      end

      context '%P - Meridian indicator, lowercase ("am" or "pm")' do
        it 'hours are before noon' do
          expect(described_class.new(8, 0, 0).strftime('%P')).to eq('am')
        end

        it 'hours are after noon' do
          expect(described_class.new(13, 0, 0).strftime('%P')).to eq('pm')
        end
      end

      context '%p - Meridian indicator, uppercase ("AM" or "PM")' do
        it 'hours are before noon' do
          expect(described_class.new(8, 0, 0).strftime('%p')).to eq('AM')
        end

        it 'hours are after noon' do
          expect(described_class.new(13, 0, 0).strftime('%p')).to eq('PM')
        end
      end

      context '%M - Minute of the hour (00..59)' do
        it 'min is one digit' do
          expect(described_class.new(0, 8, 0).strftime('%M')).to eq('08')
        end

        it 'min is two digits' do
          expect(described_class.new(0, 12, 0).strftime('%M')).to eq('12')
        end
      end

      context '%S - Second of the minute (00..60)' do
        it 'sec is one digit' do
          expect(described_class.new(0, 0, 8).strftime('%S')).to eq('08')
        end

        it 'sec is two digits' do
          expect(described_class.new(0, 0, 12).strftime('%S')).to eq('12')
        end
      end
    end

    context 'literals' do
      it '%n - Newline character (\n)' do
        expect(described_class.at(0).strftime('%n')).to eq("\n")
      end

      it '%t - Tab character (\t)' do
        expect(described_class.at(0).strftime('%t')).to eq("\t")
      end

      it '%% - Literal "%" character' do
        expect(described_class.at(0).strftime('%%')).to eq('%')
      end
    end

    context 'combinations' do
      it '%r - 12-hour time (%I:%M:%S %p)' do
        expect(described_class.new(1, 0, 12).strftime('%r')).to eq('01:00:12 AM')
      end

      it '%R - 24-hour time (%H:%M)' do
        expect(described_class.new(1, 0, 12).strftime('%R')).to eq('01:00')
      end

      %w(X T).each do |combination|
        it "%#{combination} - 24-hour time (%H:%M:%S)" do
          expect(described_class.new(1, 0, 12).strftime("%#{combination}")).to eq('01:00:12')
        end
      end
    end
  end

  describe '#succ' do
    it "returns a new #{described_class} object, one second later than the original" do
      current_time = described_class.new(0)
      new_time = current_time.succ

      expect(current_time).not_to equal(new_time)
      expect(new_time).to eq(described_class.new(1))
    end

    it 'rolls over time when greater than 23:59:59' do
      expect(described_class.new(23, 59, 59).succ).to eq(described_class.new(0, 0, 0))
    end
  end

  describe '#to_a' do
    subject { described_class.new(2, 3, 4) }

    its(:to_a) { should == [2, 3, 4] }
  end

  describe '#to_f' do
    subject { described_class.new(300) }

    its(:to_f) { should == 300.0 }
  end

  describe '#to_i' do # aliases: tv_sec
    subject { described_class.new(300) }

    its(:to_i) { should == 300 }
  end

  describe '#to_s' do # aliases: asctime, ctime, inspect
    subject { described_class.new(2, 4, 6) }

    its(:to_s) { should == '02:04:06' }
  end
end
