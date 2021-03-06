RSpec.describe PairingStrategies::Swiss do
  let(:pairer) { described_class.new(round) }
  let(:round) { create(:round, number: 1, tournament: tournament) }
  let(:tournament) { create(:tournament) }
  let(:nil_player) { double('NilPlayer', id: nil) }

  before do
    allow(NilPlayer).to receive(:new).and_return(nil_player)
  end

  context 'with four players' do
    %i(jack jill hansel gretel).each do |name|
      let!(name) do
        create(:player, name: name.to_s.humanize, tournament: tournament)
      end
    end

    it 'creates pairings' do
      pairer.pair!

      round.reload

      expect(round.pairings.count).to eq(2)
    end

    context 'after some rounds' do
      before do
        create(:pairing, player1: jack, player2: jill, score1: 6, score2: 0)
        create(:pairing, player1: hansel, player2: gretel, score1: 4, score2: 1)
      end

      it 'pairs based on points' do
        pairer.pair!

        round.reload

        round.pairings.each do |pairing|
          expect(pairing.players).to match_array([jack, hansel]) if pairing.players.include? jack
          expect(pairing.players).to match_array([jill, gretel]) if pairing.players.include? jill
        end
      end

      it 'avoids previous matchups' do
        create(:pairing, player1: jack, player2: hansel)

        pairer.pair!

        round.reload

        round.pairings.each do |pairing|
          expect(pairing.players).to match_array([jack, gretel]) if pairing.players.include? jack
          expect(pairing.players).to match_array([jill, hansel]) if pairing.players.include? jill
        end
      end
    end
  end

  context 'with three players' do
    %i(snap crackle pop).each do |name|
      let!(name) do
        create(:player, name: name.to_s.humanize, tournament: tournament)
      end
    end

    it 'creates bye' do
      pairer.pair!

      round.reload

      expect(
        round.pairings.map(&:players).flatten
      ).to contain_exactly(snap, crackle, pop, nil_player)
    end

    it 'gives win against bye' do
      pairer.pair!

      round.reload.pairings.each do |pairing|
        expect(
          [pairing.score1, pairing.score2]
        ).to match_array(
          (pairing.players.include? nil_player) ? [0,6] : [nil, nil]
        )
      end
    end

    context 'after multiple rounds' do
      before do
        create(:pairing, player1: snap, score1: 6)
        create(:pairing, player1: crackle, score1: 3)
        create(:pairing, player1: pop, player2: nil, score1: 1, score2: 0)
      end

      it 'avoids previous byes' do
        pairer.pair!

        round.reload

        round.pairings.each do |pairing|
          expect(pairing.players).not_to match_array([pop, nil_player]) if pairing.players.include? pop
        end
      end
    end

    context 'with drop' do
      before do
        pop.update active: false
      end

      it 'excludes dropped players' do
        pairer.pair!

        round.reload

        expect(
          round.pairings.map(&:players).flatten
        ).to contain_exactly(snap, crackle)
      end
    end
  end
end
